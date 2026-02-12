const std    = @import("std");
const json   = @import("json");
const zap    = @import("zap");
const sqlite = @import("sqlite");
const model          = @import("./model.zig");
const Authentication = @import("../auth.zig");
const config         = @import("../config.zig");
const util           = @import("../util.zig");

pub const NamePass = struct {
	const Self = @This();

	name: []const u8,
	pass: []const u8,

	pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
		alloc.free(self.name);
		alloc.free(self.pass);
	}
};

pub const Signup = struct {
	const Self = @This();
	pub const Path = "/signup";

	path: []const u8 = Self.Path,
	error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

	alloc:       std.mem.Allocator,
	io:          std.Io,
	usersTable: *model.Table,
	auth:        Authentication,

	pub fn post(self: *Self, req: zap.Request) !void {
		// parse body
		const body = req.body
			orelse return util.sendBody(req, .bad_request, "body was empty");
		var reader = std.Io.Reader.fixed(body);
		
		var payload = json.parse(NamePass, self.alloc, &reader)
			catch return util.sendBody(req, .bad_request, "failed parsing body");
		defer payload.deinit(self.alloc);

		// insert in db
		const id = self.usersTable.insert(self.alloc, self.io, payload.name, payload.pass)
			catch return util.sendBody(req, .internal_server_error, "failed inserting in users table");

		// set session cookie
		const cookie = self.auth.authenticator.Encode(self.alloc, self.io, id)
			catch return util.sendBody(req, .internal_server_error, "failed encoding session cookie");
		defer self.alloc.free(cookie);

		self.auth.setCookie(req, cookie)
			catch return util.sendBody(req, .internal_server_error, "failed setting session cookie");

		// TODO redirect?
		req.setStatus(.ok);
	}
};

pub const Login = struct {
	const Self = @This();
	pub const Path = "/login";

	path: []const u8 = Self.Path,
	error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

	alloc:       std.mem.Allocator,
	io:          std.Io,
	usersTable: *model.Table,
	auth:        Authentication,

	pub fn post(self: *Self, req: zap.Request) !void {
		// parse body
		const body = req.body
			orelse return util.sendBody(req, .bad_request, "body was empty");

		var reader = std.Io.Reader.fixed(body);
		var payload = json.parse(NamePass, self.alloc, &reader)
			catch return util.sendBody(req, .bad_request, "failed parsing body");
		defer payload.deinit(self.alloc);

		// verify
		// TODO better err handling
		const id = self.usersTable.verifyNamePass(self.alloc, self.io, payload.name, payload.pass)
			catch return util.sendBody(req, .unauthorized, "failed verifying name and pass");

		// set session cookie
		const cookie = self.auth.authenticator.Encode(self.alloc, self.io, id)
			catch return util.sendBody(req, .internal_server_error, "failed encoding session cookie");
		defer self.alloc.free(cookie);

		self.auth.setCookie(req, cookie)
			catch return util.sendBody(req, .internal_server_error, "failed setting session cookie");

		// TODO redirect?
		req.setStatus(.ok);
	}
};

// TODO caching
pub const Users = struct {
	const Self = @This();
	pub const Path = "/usernames";

	path: []const u8 = Self.Path,
	error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

	alloc:       std.mem.Allocator,
	io:          std.Io,
	usersTable: *model.Table,

	fn deinitNames(alloc: std.mem.Allocator, names: [][]const u8) void {
		for (names) |v| alloc.free(v);
		alloc.free(names);
	}

	pub fn get(self: *Self, req: zap.Request) !void {
		const names = self.usersTable.selectNames(self.alloc)
			catch return util.sendBody(req, .internal_server_error, "failed to read user names");
		defer Self.deinitNames(self.alloc, names);

		const body = util.payloadToJson(self.alloc, names)
			catch return util.sendBody(req, .internal_server_error, "failed serializing names");
		defer self.alloc.free(body);

		return util.sendJson(req, .ok, body);
	}
};

test {
	const alloc = std.testing.allocator;
	var singleThreaded: std.Io.Threaded = .init_single_threaded;
	const io = singleThreaded.io();

	var setup = util.TestingSetup.init(alloc, io, false);
	defer setup.deinit();

	var usersTable = model.Table.init(&setup.db);

	var signup = Signup {.alloc = alloc, .io = io, .usersTable = &usersTable, .auth = setup.auth};
	var login  = Login  {.alloc = alloc, .io = io, .usersTable = &usersTable, .auth = setup.auth};
	try setup.listener.register(&signup);
	try setup.listener.register(&login);

	try setup.startServer(io);

	// test signup
	{
		//const cookie = try Signup.postReq(alloc, &setup.cli, .{.name = "a", .pass = "b"});
		//alloc.free(cookie);
	}

	// test login
	{
		//const cookie = try Login.postReq(alloc, &setup.cli, .{.name = "a", .pass = "b"});
		//alloc.free(cookie);
	}
}
