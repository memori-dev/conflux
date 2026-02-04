const std = @import("std");
const users         = @import("../users/model.zig");
const usersHandlers = @import("../users/handlers.zig");
const util          = @import("../util.zig");

pub const Cli = struct {
	const Self = @This();

	auth: ?[]const u8 = null,

	alloc: std.mem.Allocator,
	io:    std.Io,
	cli:   std.http.Client,

	pub fn init(alloc: std.mem.Allocator, io: std.Io) Self {
		return .{
			.alloc = alloc,
			.io = io,
			.cli = std.http.Client {.allocator = alloc, .io = io},
		};
	}

	pub fn deinit(self: *Self) void {
		if (self.auth) |v| self.alloc.free(v);
	}

	pub fn login(self: *Self, name: []const u8, pass: []const u8) !void {
		const auth = try usersHandlers.Login.postReq(self.alloc, &self.cli, .{.name = name, .pass = pass});
		if (self.auth) |v| self.alloc.free(v);
		self.auth = auth;
	}

	pub fn logout(self: *Self) void {
		if (self.auth) |v| self.alloc.free(v);
		self.auth = null;
	}

	pub fn signup(self: *Self, name: []const u8, pass: []const u8) !void {
		const auth = try usersHandlers.Signup.postReq(self.alloc, &self.cli, .{.name = name, .pass = pass});
		if (self.auth) |v| self.alloc.free(v);
		self.auth = auth;
	}
};

test {
	const testingKeyPair = @import("auth").testingKeyPair;
	
	const alloc = std.testing.allocator;
	var singleThreaded: std.Io.Threaded = .init_single_threaded;
	const io = singleThreaded.io();

	var setup = util.TestingSetup.init(alloc, io, false);
	defer setup.deinit();

	var usersTable = users.Table.init(&setup.db);
	const keyPair = testingKeyPair() catch unreachable;

	var signup = usersHandlers.Signup {.alloc = alloc, .io = io, .usersTable = &usersTable, .keyPair = keyPair};
	var login  = usersHandlers.Login  {.alloc = alloc, .io = io, .usersTable = &usersTable, .keyPair = keyPair};
	try setup.listener.register(&signup);
	try setup.listener.register(&login);

	try setup.startServer(io);

	var cli = Cli.init(alloc, io);
	defer cli.deinit();

	const name = "name";
	const pass = "pass";
	
	try cli.signup(name, pass);
	try std.testing.expect(cli.auth != null);
	
	cli.logout();
	try std.testing.expect(cli.auth == null);

	try cli.login(name, pass);
	try std.testing.expect(cli.auth != null);
}
