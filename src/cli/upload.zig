const std = @import("std");
const filesHandlers  = @import("../files/handlers.zig");
const uploadSegments = @import("../fileSegments/model.zig");

const Hashes = struct {
	file: [44]u8,
	segments: [][44]u8,
}

pub fn buildHashes(alloc: std.mem.Allocator, io: std.Io, file: std.Io.File, segmentCount: u64) !Hashes {
	var blake3 = std.crypto.hash.Blake3.init(.{});
	var blake3Buf: [32]u8 = undefined;

	var segments = std.ArrayList([44]u8){};
	errdefer segments.deinit(alloc);
	try segments.ensureTotalCapacityPrecise(alloc, segmentCount);

	var readBuf: [uploadSegments.segmentSize]u8 = undefined;
	var blake3Base64Buf: [44]u8 = undefined;

	for (0..segmentCount) |i| {
		var segmentBlake3 = std.crypto.hash.Blake3.init(.{});

		const len = try file.readPositionalAll(io, &readBuf, i * uploadSegments.segmentSize);
		blake3.update(readBuf[0..len]);
		segmentBlake3.update(readBuf[0..len]);

		segmentBlake3.final(&blake3Buf);
		_ = std.base64.Base64Encoder.encode(&std.base64.standard.Encoder, &blake3Base64Buf, &blake3Buf);
		segments.appendAssumeCapacity(blake3Base64Buf);

	}
	blake3.final(&blake3Buf);
	_ = std.base64.Base64Encoder.encode(&std.base64.standard.Encoder, &blake3Base64Buf, &blake3Buf);

	return .{.file = blake3Base64Buf, .segments = segments.items};
}

pub fn upload(path: []const u8, fsId: u32, parent: ?u32) !void {
	// alloc
	var gpa = std.heap.GeneralPurposeAllocator(.{.thread_safe = true}){};
	defer _ = gpa.detectLeaks();
	const alloc = gpa.allocator();

	// io
	var singleThreaded: std.Io.Threaded = .init_single_threaded;
	const io = singleThreaded.io();

	// file
	var file = try std.Io.Dir.openFileAbsolute(io, path, .{});
	defer file.close(io);
	const stat = try file.stat(io);

	// cli
	var cli = std.http.Client{.io = io, .allocator = alloc};
	defer cli.deinit();

	// hashes
	const segmentCount = try std.math.divCeil(u64, stat.size, uploadSegments.segmentSize);
	const hashes = try buildHashes(alloc, io, file, segmentCount);
	defer alloc.free(hashes.segments);

	// init req
	var iter = std.mem.splitBackwardsScalar(u8, path, '/');
	const id = try filesHandlers.Init.postReq(alloc, &cli, .{
		.upload = .{
			.fsId = fsId,
			.parent = parent,
			.name = iter.first(),
			.created = @intCast(stat.mtime.toSeconds()),
			.size = stat.size,
			.blake3 = hashes.file,
		},
		.segmentHashes = hashes.segments,
	});

	// upload all segments
	for (0..segmentCount) |i| try filesHandlers.Segment.postReq(io, &cli, file, id, i);

	// TODO get upload row from db
}
