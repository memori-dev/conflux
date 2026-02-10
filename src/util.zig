const std    = @import("std");
const sqlite = @import("sqlite");
const zap    = @import("zap");
const Authentication = @import("./auth.zig");
const config         = @import("./config.zig");

//
// REQUESTS
//

pub fn dumpHeaders(head: std.http.Client.Response.Head) void {
	var it = head.iterateHeaders();
	std.debug.print("### headers ###\n", .{});
	while (it.next()) |v| std.debug.print("\t'{s}':'{s}'\n", .{v.name, v.value});
}

pub fn dumpHead(head: std.http.Client.Response.Head) void {
	std.debug.print("\n\n\n### head ###\n", .{});
	std.debug.print("\tversion: {any}\n", .{head.version});
	std.debug.print("\tstatus: {any}\n", .{head.status});
	std.debug.print("\treason: '{s}'\n", .{head.reason});
	std.debug.print("\tlocation: '{s}'\n", .{head.location orelse "null"});
	std.debug.print("\tcontent_type: '{s}'\n", .{head.content_type orelse "null"});
	std.debug.print("\tcontent_disposition: '{s}'\n", .{head.content_disposition orelse "null"});
	std.debug.print("\tkeep_alive: '{any}'\n", .{head.keep_alive});
	std.debug.print("\tcontent_length: {d}\n", .{head.content_length orelse 0});
	std.debug.print("\ttransfer_encoding: {any}\n", .{head.transfer_encoding});
	std.debug.print("\tcontent_encoding: {any}\n", .{head.content_encoding});
}

pub fn getSetCookie(alloc: std.mem.Allocator, head: std.http.Client.Response.Head) ![]const u8 {
	var it = head.iterateHeaders();
	while (it.next()) |v| if (std.mem.eql(u8, v.name, "set-cookie")) return alloc.dupe(u8, v.value);
	
	return error.CookieNotSet;
}

pub fn payloadToJson(alloc: std.mem.Allocator, payload: anytype) ![]u8 {
	const fmt = std.json.fmt(payload, .{});
	var writer = std.Io.Writer.Allocating.init(alloc);
	defer writer.deinit();
	try fmt.format(&writer.writer);
	return writer.toOwnedSlice();
}

pub fn postPayload(comptime path: []const u8, alloc: std.mem.Allocator, cli: *std.http.Client, payload: anytype) !std.http.Client.Response {
	const body = try payloadToJson(alloc, payload);
	defer alloc.free(body);

	var req = try cli.request(.POST, std.Uri.parse(config.host ++ path) catch unreachable, .{
		.headers = .{.accept_encoding = .{.override = "gzip, deflate, br, zstd"}},
		.extra_headers = &.{.{.name = "Content-Type", .value = "application/json"}},
	});
	defer req.deinit();

	try req.sendBodyComplete(body);
	return req.receiveHead(&.{});	
}

pub fn readResponseBody(comptime len: usize, res: *std.http.Client.Response, buf: *[len]u8) ![]const u8 {
	var rdrBuf: [len]u8 = undefined;
	const reader = res.reader(&rdrBuf);

	const toRead = @min(res.head.content_length.?, buf.len);
	try reader.readSliceAll(buf[0..toRead]);

	return buf[0..toRead];
}

//
// SQLITE
//

pub fn mustCreateTable(db: *sqlite.Db, tableName: []const u8, comptime cmd: []const u8) void {
	var diags = sqlite.Diagnostics{};
	db.exec(cmd, .{.diags = &diags}, .{})
		catch std.process.fatal("failed creating table: '{s}'\n\tdiag msg: {s}\n\tdiag err code: {d}\n\tdiag err near: {d}\n\tdiag err msg {s}\n",
			.{tableName, diags.message, diags.err.?.code, diags.err.?.near, diags.err.?.message},
		);
}

pub fn latestId(comptime T: type, db: *sqlite.Db, comptime tableName: []const u8) std.atomic.Value(T) {
	const res = db.one(u32, "SELECT id FROM " ++ tableName ++ " ORDER BY id DESC LIMIT 1", .{}, .{}) catch unreachable;
	if (res) |id| return std.atomic.Value(T).init(id + 1);
	
	return std.atomic.Value(T).init(0);
}

//
// HANDLERS
//

pub fn htmlTemplate(comptime jsFileName: []const u8) []const u8 {
	return \\ <!DOCTYPE html>
	\\ <html lang="en">
	\\ <head>
	\\ <meta charset="UTF-8">
	\\ <meta name="viewport" content="width=device-width, initial-scale=1.0">
	\\ <title>conflux</title>
	\\ </head>
	\\ <body style="background: #0a0a0a; margin: 0">
		++ "<script type=\"module\" src=\"bundle/" ++ jsFileName ++ ".js\"></script>" ++
	\\ </body>
	\\ </html>
	;
}

pub fn sendBody(req: zap.Request, status: zap.http.StatusCode, body: []const u8) !void {
	req.setStatus(status);
	return req.sendBody(body);
}

//pub fn sendErr(comptime ErrEnum: type, req: zap.Request, status: zap.http.StatusCode, err: ErrEnum) !void {
	//req.setStatus(status);
	// TODO set header & err #
	//return req.sendBody(@tagName(err));
//}

pub fn sendJson(req: zap.Request, status: zap.http.StatusCode, body: []const u8) !void {
	req.setStatus(status);
	return req.sendJson(body);
}

// TODO pub fn parseQueryParams()

pub fn parseFormData(comptime T: type, alloc: std.mem.Allocator, req: zap.Request) !T {
	req.parseBody() catch |err| std.debug.print("Parse Body error: {any}. Expected if body is empty\n", .{err});
	// debugging
	if (req.body) |body| std.debug.print("body[{d}]: {s}\n", .{body.len, body});

	var params = try req.parametersToOwnedList(alloc);
	defer params.deinit();

	// TODO check for invalid keys
	// TODO check for missing keys

	for (params.items) |*kv| if (kv.value) |*v| {
		std.debug.print("param kv: `{s}` -> {any}\n", .{ kv.key, v });

		switch (v.*) {
			//.Int => |i| switch (kv.key) {
			.Int => switch (kv.key) {
				//"fsId"    => data.fsId    = i,
				//"parent"  => data.parent  = i,
				//"created" => data.created = i,
				//"size"    => data.size    = i,
				else => {
					req.setStatus(.bad_request);
					return req.sendBody("unexpected input key"); // TODO add key name
				},
			},
			//.String => |s| switch (kv.key) {
			.String => switch (kv.key) {
				//"name" => data.name = s,
				else => {
					req.setStatus(.bad_request);
					return req.sendBody("unexpected input key"); // TODO add key name
				},
			},
			else => {
				req.setStatus(.bad_request);
				return req.sendBody("unexpected input type"); // TODO add type info
			},
		}

		// TODO v.free(self.alloc);
	};

	return .{};
}

//
// TESTING
//

pub fn testingDb() sqlite.Db {
	return sqlite.Db.init(.{
		.mode = sqlite.Db.Mode{ .Memory = {}},
		.open_flags = .{.write = true, .create = true},
		.threading_mode = .SingleThread,
	}) catch unreachable;
}

fn fallback(r: zap.Request) !void {
	r.setStatus(.not_found);
}

pub fn testingServer(alloc: std.mem.Allocator, io: std.Io, log: bool) zap.Endpoint.Listener {
	return zap.Endpoint.Listener.init(alloc, .{.port = config.port, .io = io, .on_request = fallback, .log = log});
}

pub const TestingSetup = struct {
	const Self = @This();

	db:       sqlite.Db,
	listener: zap.Endpoint.Listener,
	cli:      std.http.Client,
	auth:     Authentication = .{
		.authenticator = .{.keyPair = @import("auth").testingKeyPair},
		.cookieName = "id",
		.ttl = 60*60*24*90,
	},

	pub fn init(alloc: std.mem.Allocator, io: std.Io, log: bool) Self {
		return .{
			.db = testingDb(),
			.listener = testingServer(alloc, io, log),
			.cli = .{.allocator = alloc, .io = io},
		};
	}

	pub fn deinit(self: *Self) void {
		self.listener.deinit();
		self.cli.deinit();
		zap.stop();
	}

	pub fn startServer(self: *Self, io: std.Io) !void {
		try self.listener.listen();
		_ = try std.Thread.spawn(.{}, zap.start, .{zap.fio.struct_fio_start_args{.threads = 1, .workers = 1}});
		io.sleep(.{.nanoseconds = 500000000}, .real) catch unreachable; // TODO better way to await server start?
	}
};
