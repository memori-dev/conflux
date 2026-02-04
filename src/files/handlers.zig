const std            = @import("std");
const json           = @import("json");
const zap            = @import("zap");
const sqlite         = @import("sqlite");

const files        = @import("./model.zig");
const path         = @import("../disk/path.zig");
const Disk         = @import("../disk/disk.zig").Disk;
const fileSegments = @import("../fileSegments/model.zig");
const util         = @import("../util.zig");

pub const Init = struct {
	const Self = @This();
	const Path = "/uploadInit";

	path: []const u8 = Self.Path,
	error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

	alloc: std.mem.Allocator,
	io:    std.Io,
	
	disk: Disk,

	db:                *sqlite.Db,
	filesTable:        *files.Table,
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
		var data = json.parse(Self.Body, self.alloc, &reader)
			catch return util.sendBody(req, .bad_request, "failed parsing body");
		defer data.deinit(self.alloc);

		// transactions
		var tx = try self.db.savepoint(Self.Path);
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
	pub fn postReq(alloc: std.mem.Allocator, cli: *std.http.Client, payload: Self.Body) !u64 {
		var res = try util.postPayload(Self.Path, alloc, cli, payload);
		util.dumpHead(res.head);
		util.dumpHeaders(res.head);
		var outBuf: [128]u8 = undefined;
		const out = try util.readResponseBody(128, &res, &outBuf);
		return std.fmt.parseInt(u64, out, 10);
	}
};

// TODO move into fileSegments (consider merging with Segment as get & post @ "/fileSegments")
// TODO if no segments exist, double check that uploadDb.complete is set to true
pub const Progress = struct {
	const Self = @This();

	path: []const u8 = "/uploadProgress",
	error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

	alloc: std.mem.Allocator,
	fileSegmentsTable: *fileSegments.Table,

	// TODO cookies & access handling
	// ?fileId={d}
	pub fn get(self: *Self, req: zap.Request) !void {
		// parse fileId
		req.parseQuery();
		const fileIdStr = req.getParamSlice("fileId")
			orelse return util.sendBody(req, .bad_request, "missing fileId in query params");
		const fileId = std.fmt.parseInt(files.Id, fileIdStr, 10)
			catch return util.sendBody(req, .bad_request, "invalid fileId query param");

		// select from db
		const hashes = self.fileSegmentsTable.selectIdxBlake3(self.alloc, fileId)
			catch return util.sendBody(req, .internal_server_error, "failed retrieving rows from fileSegments table");
		defer self.alloc.free(hashes);

		// sends hashes
		var out: std.Io.Writer.Allocating = .init(self.alloc);
		std.json.Stringify.value(hashes, .{}, &out.writer)
			catch return util.sendBody(req, .internal_server_error, "failed allocating hashes");
		var arr = out.toArrayList();
		defer arr.deinit(self.alloc);

		return util.sendJson(req, .ok, arr.items);
	}
};

// TODO move into fileSegments
pub const Segment = struct {
	const Self = @This();

	path: []const u8 = "/uploadSegment",
	error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

	alloc: std.mem.Allocator,
	io: std.Io,
	disk: Disk,
	filesTable:        *files.Table,
	fileSegmentsTable: *fileSegments.Table,

	// TODO cookies & access handling
	// ?fileId={d}&idx={d}
	// the body is [uploadSegments.segmentSize]u8 of file data
	pub fn post(self: *Self, req: zap.Request) !void {
		// parse fileId and idx
		const fileIdStr = req.getParamSlice("fileId")
			orelse return util.sendBody(req, .bad_request, "missing fileId in query params");
		const fileId = std.fmt.parseInt(files.Id, fileIdStr, 10)
			catch return util.sendBody(req, .bad_request, "invalid fileId query param");

		const idxStr = req.getParamSlice("idx")
			orelse return util.sendBody(req, .bad_request, "missing idx in query params");
		const idx = std.fmt.parseInt(u64, idxStr, 10)
			catch return util.sendBody(req, .bad_request, "invalid idx query param");

		// get & hash body
		const body = req.body 
			orelse return util.sendBody(req, .bad_request, "empty body");
	
		var blake3 = std.crypto.hash.Blake3.init(.{});
		blake3.update(body);
		var blake3Buf: [32]u8 = undefined;
		blake3.final(&blake3Buf);
		var blake3Base64Buf: [44]u8 = undefined;
		_ = std.base64.Base64Encoder.encode(&std.base64.standard.Encoder, &blake3Base64Buf, &blake3Buf);

		// get hash from db & check equality
		const hash = (self.fileSegmentsTable.selectBlake3(fileId, idx)
			catch return util.sendBody(req, .internal_server_error, "failed reading from fileSegments table"))
			orelse return util.sendBody(req, .conflict, "segment has already been uploaded");
		if (!std.mem.eql(u8, &blake3Base64Buf, &hash))
			return util.sendBody(req, .conflict, "hash of segment does not match fileSegment value");

		// open and write to file
		var file = self.disk.openWrite(fileId)
			catch return util.sendBody(req, .internal_server_error, "failed to open file for writing");
		defer file.close(self.io);

		file.writePositionalAll(self.io, body, fileSegments.segmentSize * idx)
			catch return util.sendBody(req, .internal_server_error, "failed to write segment to file");

		// delete from fileSegments
		// if this fails the segment will be written, but effectively dropped and will need to be retried
		self.fileSegmentsTable.delete(fileId, idx)
			catch return util.sendBody(req, .internal_server_error, "failed to update fileSegments table");
		
		// if all are uploaded change uploadDB.complete to true
		const remaining = self.fileSegmentsTable.count(fileId)
			catch return util.sendBody(req, .ok, "upload succeeded, failed to get remaining segements");
		if (remaining == 0) self.filesTable.updateComplete(fileId)
			catch return util.sendBody(req, .ok, "upload succeeded, failed to set file completed to true");

		return req.setStatus(.ok);
	}

	// TODO cookies
	pub fn postReq(io: std.Io, cli: *std.http.Client, file: std.Io.File, fileId: usize, idx: usize) !void {
		var buf: [fileSegments.segmentSize]u8 = undefined;
		const n = try file.readPositionalAll(io, &buf, idx * fileSegments.segmentSize);

		const uriFmt = "http://localhost:8080/uploadSegment?fileId={d}&idx={d}";
		var uriBuf: [uriFmt.len+20+20]u8 = undefined;
		const uri = std.fmt.bufPrint(&uriBuf, uriFmt, .{fileId, idx}) catch unreachable;

		var req = try cli.request(.POST, std.Uri.parse(uri) catch unreachable, .{
			.headers = .{.accept_encoding = .{.override = "gzip, deflate, br, zstd"}},
			.extra_headers = &.{
				.{.name = "Content-Type", .value = "application/json"},
				//.{.name = "Cookie", .value = TODO},
			},
		});
		defer req.deinit();

		try req.sendBodyComplete(buf[0..n]);
		var response = try req.receiveHead(&.{});

		util.dumpHeaders(response.head);
		util.dumpHead(response.head);

		// TODO handle status / errors
		switch (response.head.status) {
			.ok => return,
			else => return error.UploadFailed,
		}
	}
};

// TODO browser uploads
// TODO get the timestamp of file creation https://stackoverflow.com/questions/998098/getting-the-original-files-create-date-upon-upload
// TODO
//// const filename = f.filename orelse "unknown";
//// const data = f.data orelse "";
const Browser = struct {
	const Self = @This();

	pub fn post(self: *Self, req: zap.Request) !void {
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
