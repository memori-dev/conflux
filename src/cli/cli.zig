const std  = @import("std");
const json = @import("json");

const config = @import("../config.zig");
const FilesHandler = @import("../files/handler.zig");
const fileSegments = @import("../fileSegments/model.zig");
const FileSegmentsHandler = @import("../fileSegments/handler.zig");
const fileStores = @import("../fileStore/model.zig");
const FileStoresHandler = @import("../fileStore/handler.zig");
const users = @import("../users/model.zig");
const usersHandlers = @import("../users/handlers.zig");
const util = @import("../util.zig");

// TODO util.Uri(comptime path, comptime additionalLen) w known len for formatting, and std.uri.parse catch unreachable
const Self = @This();

auth:  []const u8,
alloc: std.mem.Allocator,
io:    std.Io,
cli:   *std.http.Client,

pub fn deinit(self: *Self) void {
	self.alloc.free(self.auth);
	self.cli.deinit();
	self.alloc.destroy(self.cli);
}

pub fn login(alloc: std.mem.Allocator, io: std.Io, name: []const u8, pass: []const u8) !Self {
	const cli = try alloc.create(std.http.Client);
	cli.* = std.http.Client {.allocator = alloc, .io = io};
	
	// TODO handle status / errors
	const body = try util.payloadToJson(alloc, usersHandlers.NamePass {.name = name, .pass = pass});
	defer alloc.free(body);

	var req = try cli.request(.POST, std.Uri.parse(config.baseUrl ++ usersHandlers.Login.Path) catch unreachable, .{});
	defer req.deinit();

	try req.sendBodyComplete(body);
	var res = try req.receiveHead(&.{});
	util.dumpHeaders(res.head);
	util.dumpHead(res.head);

	const auth = try util.getSetCookie(alloc, res.head);
	std.debug.print("auth: {s}\n", .{auth});

	return .{
		.auth = auth,
		.alloc = alloc,
		.io = io,
		.cli = cli,
	};
}

pub fn signup(alloc: std.mem.Allocator, io: std.Io, name: []const u8, pass: []const u8) !Self {
	const cli = try alloc.create(std.http.Client);
	cli.* = std.http.Client {.allocator = alloc, .io = io};
	
	const body = try util.payloadToJson(alloc, usersHandlers.NamePass {.name = name, .pass = pass});
	defer alloc.free(body);

	var req = try cli.request(.POST, std.Uri.parse(config.baseUrl ++ usersHandlers.Signup.Path) catch unreachable, .{});
	defer req.deinit();

	try req.sendBodyComplete(body);
	var res = try req.receiveHead(&.{});
	util.dumpHeaders(res.head);
	util.dumpHead(res.head);

	const auth = try util.getSetCookie(alloc, res.head);
	std.debug.print("auth: {s}\n", .{auth});

	return .{
		.auth = auth,
		.alloc = alloc,
		.io = io,
		.cli = cli,
	};
}

pub fn getFileStore(self: *Self) ![]const fileStores.Row {
	std.debug.print("auth: {s}\n", .{self.auth});

	var req = try self.cli.request(.GET, std.Uri.parse(config.baseUrl ++ FileStoresHandler.Path) catch unreachable, .{
		.extra_headers = &.{.{.name = "Cookie", .value = self.auth}},
	});
	defer req.deinit();

	try req.sendBodiless();
	var res = try req.receiveHead(&.{});
	util.dumpHeaders(res.head);
	util.dumpHead(res.head);

	return util.parseJsonResponse([]const fileStores.Row, self.alloc, &res);
}

pub fn postFileStore(self: *Self, name: []const u8) !fileStores.Id {
	const uriFmt = config.baseUrl ++ FileStoresHandler.Path ++ "?name={s}";
	var buf: [uriFmt+fileStores.maxNameLen]u8 = undefined;
	const uri = std.fmt.bufPrint(&buf, uriFmt, .{name}) catch unreachable;

	var req = try self.cli.request(.POST, std.Uri.parse(uri) catch unreachable, .{
		.extra_headers = &.{.{.name = "Cookie", .value = self.auth}},
	});
	defer req.deinit();

	try req.sendBodiless();
	var response = try req.receiveHead(&.{});
	util.dumpHeaders(response.head);
	util.dumpHead(response.head);

	// TODO handle status / errors
	return switch (response.head.status) {
		// TODO .ok => try std.fmt.parseInt(),
		.ok => 1,
		else => error.UploadFailed,
	};
}

const Hashes = struct {
	file: [44]u8,
	segments: [][44]u8,
};

pub fn buildHashes(alloc: std.mem.Allocator, io: std.Io, file: std.Io.File, segmentCount: u32) !Hashes {
	var blake3 = std.crypto.hash.Blake3.init(.{});
	var blake3Buf: [32]u8 = undefined;

	var segments = std.ArrayList([44]u8){};
	errdefer segments.deinit(alloc);
	try segments.ensureTotalCapacityPrecise(alloc, segmentCount);

	var readBuf: [fileSegments.segmentSize]u8 = undefined;
	var blake3Base64Buf: [44]u8 = undefined;

	for (0..segmentCount) |i| {
		var segmentBlake3 = std.crypto.hash.Blake3.init(.{});

		const len = try file.readPositionalAll(io, &readBuf, i * fileSegments.segmentSize);
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

pub fn uploadFile(self: *Self, path: []const u8, fileStoreId: fileStores.Id, parent: ?users.Id) !void {
	// file
	var file = try std.Io.Dir.openFileAbsolute(self.io, path, .{});
	defer file.close(self.io);
	const stat = try file.stat(self.io);

	// TODO if size <= segmentSize just upload in one go
	// hashes
	const segmentCount: u32 = @intCast(try std.math.divCeil(u64, stat.size, fileSegments.segmentSize));
	const hashes = try buildHashes(self.alloc, self.io, file, segmentCount);
	defer self.alloc.free(hashes.segments);

	// init req
	var iter = std.mem.splitBackwardsScalar(u8, path, '/');
	const id = try FilesHandler.postReq(self.alloc, self.cli, .{
		.upload = .{
			.fsId = fileStoreId,
			.parent = parent,
			.name = iter.first(),
			.created = @intCast(stat.mtime.toSeconds()),
			.size = stat.size,
			.blake3 = hashes.file,
		},
		.segmentHashes = hashes.segments,
	});

	// upload all segments
	for (0..segmentCount) |i| try FileSegmentsHandler.postReq(self.io, self.cli, file, id, i);

	// TODO get upload row from db
}

test {
	const alloc = std.testing.allocator;
	var singleThreaded: std.Io.Threaded = .init_single_threaded;
	const io = singleThreaded.io();

	var setup = util.TestingSetup.init(alloc, io, false);
	defer setup.deinit();

	var usersTable = users.Table.init(&setup.db);
	var fileStoreTable = fileStores.Table.init(&setup.db);

	var signupHandler = usersHandlers.Signup {.alloc = alloc, .io = io, .usersTable = &usersTable, .auth = setup.auth};
	try setup.listener.register(&signupHandler);
	var loginHandler  = usersHandlers.Login  {.alloc = alloc, .io = io, .usersTable = &usersTable, .auth = setup.auth};
	try setup.listener.register(&loginHandler);
	var fileStoreHandler  = FileStoresHandler  {.alloc = alloc, .io = io, .fileStoreTable = &fileStoreTable, .auth = setup.auth};
	try setup.listener.register(&fileStoreHandler);

	try setup.startServer(io);

	const name = "name";
	const pass = "pass";
	
	var cli: Self = undefined;
	
	cli = try signup(alloc, io, name, pass);
	cli.deinit();

	cli = try login(alloc, io, name, pass);
	defer cli.deinit();

	std.debug.print("fileStores: {any}\n", .{cli.getFileStore() catch unreachable});
}
