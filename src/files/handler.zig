const std    = @import("std");
const json   = @import("json");
const zap    = @import("zap");
const sqlite = @import("sqlite");
const model          = @import("./model.zig");
const Authentication = @import("../auth.zig");
const Disk           = @import("../disk/disk.zig").Disk;
const fileSegments   = @import("../fileSegments/model.zig");
const fileStore      = @import("../fileStore/model.zig");
const util           = @import("../util.zig");
const users          = @import("../users/model.zig");

const Self = @This();
pub const Path = "/files";

path: []const u8 = Path,
error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

alloc: std.mem.Allocator,
io: std.Io,
disk: Disk,
auth: Authentication,
db: *sqlite.Db,
filesTable: *model.Table,
fileStoreTable: *fileStore.Table,
fileSegmentsTable: *fileSegments.Table,

// TODO actions enum CRUD
// TODO fileStorePerms which will be passed in as ?fileStorePerms.Row
fn canPerformActionOnFileStore(userId: users.Id, fileStoreOwnerId: users.Id) bool {
	return userId == fileStoreOwnerId;
}

fn deinitRows(alloc: std.mem.Allocator, rows: []model.Row) void {
	for (rows) |*v| v.deinit(alloc);
	alloc.free(rows);
}

// TODO filtering
// TODO sorting
// TODO pagination
// ?fileStoreId={d}
pub fn get(self: *Self, req: zap.Request) !void {
	// parse query params
	const fileStoreIdStr = req.getParamSlice("fileStoreId") orelse
		return util.sendBody(req, .bad_request, "missing fileStoreId in query params");
	const fileStoreId = std.fmt.parseInt(fileStore.Id, fileStoreIdStr, 10) catch
		return util.sendBody(req, .bad_request, "invalid fileStoreId query param");

	// get user id
	const userId = self.auth.getId(self.alloc, self.io, req) catch
		return util.sendBody(req, .unauthorized, "not logged in");

	// get fileStore owner
	const fileStoreOwnerIdOpt = self.fileStoreTable.selectOwnerById(fileStoreId) catch
		return util.sendBody(req, .internal_server_error, "failed to select fileStore owner");
	const fileStoreOwnerId = fileStoreOwnerIdOpt orelse
		return util.sendBody(req, .not_found, "no fileStore was found for the given fileStore id");
	
	// check authorization
	// TODO filePerms
	// TODO pass in .select action
	if (!canPerformActionOnFileStore(userId, fileStoreOwnerId))
		return util.sendBody(req, .unauthorized, "you do not have permissions for this fileStore");

	// select files
	const rows = self.filesTable.selectRowsByFileStoreId(self.alloc, fileStoreId) catch
		return util.sendBody(req, .internal_server_error, "failed to select files");
	defer deinitRows(self.alloc, rows);

	// marshal
	const resBody = util.payloadToJson(self.alloc, rows) catch
		return util.sendBody(req, .internal_server_error, "failed to marshal files");
	defer self.alloc.free(resBody);

	return util.sendJson(req, .ok, resBody);
}

pub const Body = struct {
	upload: model.Insert,
	segmentHashes: [][44]u8,

	pub fn deinit(self: *Body, alloc: std.mem.Allocator) void {
		self.upload.deinit(alloc);
		alloc.free(self.segmentHashes);
	}
};

// TODO query param for upload methods (segmented, complete, browser or will complete work?)
pub fn post(self: *Self, req: zap.Request) !void {
	// parse body
	const body = req.body
		orelse return util.sendBody(req, .bad_request, "body was empty");

	var reader = std.Io.Reader.fixed(body);
	var data = json.parse(Body, self.alloc, &reader)
		catch return util.sendBody(req, .bad_request, "failed parsing body");
	defer data.deinit(self.alloc);

	// get user id
	const userId = self.auth.getId(self.alloc, self.io, req) catch
		return util.sendBody(req, .unauthorized, "not logged in");

	// get fileStore owner
	const fileStoreOwnerIdOpt = self.fileStoreTable.selectOwnerById(data.upload.fsId) catch
		return util.sendBody(req, .internal_server_error, "failed to select fileStore owner");
	const fileStoreOwnerId = fileStoreOwnerIdOpt orelse
		return util.sendBody(req, .not_found, "no fileStore was found for the given fileStore id");

	// check authorization
	// TODO filePerms
	// TODO pass in .insert action
	if (!canPerformActionOnFileStore(userId, fileStoreOwnerId))
		return util.sendBody(req, .unauthorized, "you do not have permissions for this fileStore");

	// transactions
	var tx = try self.db.savepoint(Path);
	defer tx.rollback();

	// insert into db
	const id = self.filesTable.insert(data.upload)
		catch return util.sendBody(req, .internal_server_error, "failed inserting into files table");

	// insert all hashes into new db
	for (data.segmentHashes, 0..) |v, i| {
		self.fileSegmentsTable.insert(.{.fileId = id, .idx = @intCast(i), .blake3 = v})
			catch return util.sendBody(req, .internal_server_error, "failed inserting into fileSegments table");
	}

	// create file
	var file = self.disk.create(id, data.upload.size)
		catch return util.sendBody(req, .internal_server_error, "failed to create file");
	file.close(self.io);

	tx.commit();

	// send id
	var buf: [10]u8 = undefined;
	return util.sendBody(req, .ok, std.fmt.bufPrint(&buf, "{d}", .{id}) catch unreachable);
}

// TODO handle status / errors
pub fn postReq(alloc: std.mem.Allocator, cli: *std.http.Client, payload: Body) !u64 {
	var res = try util.postPayload(Path, alloc, cli, payload);
	util.dumpHead(res.head);
	util.dumpHeaders(res.head);
	var outBuf: [128]u8 = undefined;
	const out = try util.readResponseBody(128, &res, &outBuf);
	return std.fmt.parseInt(u64, out, 10);
}

// TODO browser uploads, handle by merging into post w a query param for upload method
// TODO get the timestamp of file creation https://stackoverflow.com/questions/998098/getting-the-original-files-create-date-upon-upload
// TODO
//// const filename = f.filename orelse "unknown";
//// const data = f.data orelse "";
const Browser = struct {
	//const Self = @This();

	pub fn post(self: *@This(), req: zap.Request) !void {
		req.parseBody() catch |err| std.log.err("Parse Body error: {any}. Expected if body is empty", .{err});

		if (req.body) |body| std.log.info("Body length is {any}", .{body.len});

		var params = try req.parametersToOwnedList(self.alloc);
		defer params.deinit();
		for (params.items) |*kv| if (kv.value) |*v| {
			switch (v.*) {
				// single-file upload
				//zap.Request.HttpParam.Hash_Binfile => |*file| try self.uploadQueue.new(file),
				
				// multi-file upload
				zap.Request.HttpParam.Array_Binfile => |*f| {
					//for (files.*.items) |*file| try self.uploadQueue.new(file);
					f.deinit(self.alloc);
				},

				else => {
					const value: []const u8 = req.getParamSlice(kv.key) orelse "(no value)";
					std.log.debug("   {s} = {s}", .{ kv.key, value });
				},
			}
		};

		return req.setStatus(.ok);
	}
};
