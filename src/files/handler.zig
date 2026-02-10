const std    = @import("std");
const json   = @import("json");
const zap    = @import("zap");
const sqlite = @import("sqlite");
const files        = @import("./model.zig");
const Disk         = @import("../disk/disk.zig").Disk;
const fileSegments = @import("../fileSegments/model.zig");
const util         = @import("../util.zig");

const Self = @This();
pub const Path = "/files";

path: []const u8 = Path,
error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

alloc: std.mem.Allocator,
io: std.Io,
disk: Disk,
db: *sqlite.Db,
filesTable: *files.Table,
fileSegmentsTable: *fileSegments.Table,

pub const Body = struct {
	upload: files.Insert,
	segmentHashes: [][44]u8,

	pub fn deinit(self: *Body, alloc: std.mem.Allocator) void {
		self.upload.deinit(alloc);
		alloc.free(self.segmentHashes);
	}
};

// TODO cookies & access handling
pub fn post(self: *Self, req: zap.Request) !void {
	// parse body
	const body = req.body
		orelse return util.sendBody(req, .bad_request, "body was empty");

	var reader = std.Io.Reader.fixed(body);
	var data = json.parse(Body, self.alloc, &reader)
		catch return util.sendBody(req, .bad_request, "failed parsing body");
	defer data.deinit(self.alloc);

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

	// sends id
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

// TODO browser uploads
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
