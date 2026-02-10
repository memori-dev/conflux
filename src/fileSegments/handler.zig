const std    = @import("std");
const json   = @import("json");
const zap    = @import("zap");
const sqlite = @import("sqlite");
const model = @import("./model.zig");
const Disk  = @import("../disk/disk.zig").Disk;
const files = @import("../files/model.zig");
const util  = @import("../util.zig");

// TODO if no segments exist, double check that uploadDb.complete is set to true
const Self = @This();
pub const Path = "/fileSegments";

path: []const u8 = Path,
error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

alloc: std.mem.Allocator,
io: std.Io,
disk: Disk,
filesTable: *files.Table,
fileSegmentsTable: *model.Table,

// TODO cookies & access handling
// ?fileId={d}
pub fn get(self: *Self, req: zap.Request) !void {
	// parse fileId
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

// TODO getRequest

// TODO cookies & access handling
// ?fileId={d}&idx={d}
// the body is [<= uploadSegments.segmentSize]u8 of file data
pub fn post(self: *Self, req: zap.Request) !void {
	// parse query params
	const fileIdStr = req.getParamSlice("fileId")
		orelse return util.sendBody(req, .bad_request, "missing fileId in query params");
	const fileId = std.fmt.parseInt(files.Id, fileIdStr, 10)
		catch return util.sendBody(req, .bad_request, "invalid fileId query param");

	const idxStr = req.getParamSlice("idx")
		orelse return util.sendBody(req, .bad_request, "missing idx in query params");
	const idx = std.fmt.parseInt(u32, idxStr, 10)
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

	file.writePositionalAll(self.io, body, model.segmentSize * idx)
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
	var buf: [model.segmentSize]u8 = undefined;
	const n = try file.readPositionalAll(io, &buf, idx * model.segmentSize);

	const uriFmt = "http://localhost:8080/fileSegments?fileId={d}&idx={d}";
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
