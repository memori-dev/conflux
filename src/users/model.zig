const std    = @import("std");
const sqlite = @import("sqlite");
const util = @import("../util.zig");

pub const tableName = "users";
pub const nameMaxLen = 32;

const createTable = "create table if not exists " ++ tableName ++ " (" ++ \\
	\\    id   INTEGER  NOT NULL PRIMARY KEY,
	\\    name TEXT     NOT NULL UNIQUE,
	\\    pass BLOB     NOT NULL,
	\\    ts   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	\\
	\\    CHECK(LENGTH(name) <= 32)
	\\    CHECK(LENGTH(pass) == 118)
	\\)
;

pub const Id = u32;

pub const Row = struct {
	const Self = @This();

	id:   Id,
	name: []const u8,
	pass: [118]u8,
	ts:   u64,

	pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
		alloc.free(self.name);
	}
};

pub const Table = struct {
	const Self = @This();

	db: *sqlite.Db,

	pub fn init(db: *sqlite.Db) Self {
		util.mustCreateTable(db, tableName, createTable);
		return .{.db = db};
	}

	pub fn insert(self: *Self, alloc: std.mem.Allocator, io: std.Io, name: []const u8, pass: []const u8) !Id {
		const rand = std.Random.IoSource{.io = io};
		const id = rand.interface().int(Id);

		var passHash: [118]u8 = undefined;
		_ = try std.crypto.pwhash.argon2.strHash(pass, .{.allocator = alloc, .params = std.crypto.pwhash.argon2.Params.owasp_2id}, &passHash, io);
		
		try self.db.exec("INSERT INTO " ++ tableName ++ " (id, name, pass) VALUES (?1, ?2, ?3)", .{}, .{id, name, passHash});

		return id;
	}

	pub fn selectId(self: *Self, alloc: std.mem.Allocator, id: Id) !?Row {
		return self.db.oneAlloc(Row, alloc, "SELECT * FROM " ++ tableName ++ " WHERE id = (?1) LIMIT 1", .{}, .{id});
	}

	pub fn selectName(self: *Self, alloc: std.mem.Allocator, name: []const u8) !?Row {
		return self.db.oneAlloc(Row, alloc, "SELECT * FROM " ++ tableName ++ " WHERE name = ? LIMIT 1", .{}, .{name});
	}

	pub fn selectNames(self: *Self, alloc: std.mem.Allocator) ![][]const u8 {
		const query = "SELECT name FROM " ++ tableName;
		var stmt = try self.db.prepare(query);
		defer stmt.deinit();

		return stmt.all([]const u8, alloc, .{}, .{});
	}

	pub fn delete(self: *Self, id: u64) !void {
		return self.db.exec("DELETE FROM " ++ tableName ++ " WHERE id = (?1)", .{}, .{id});
	}

	pub fn verifyNamePass(self: *Self, alloc: std.mem.Allocator, io: std.Io, name: []const u8, pass: []const u8) !Id {
		var row = try self.selectName(alloc, name) orelse return error.NameNotFound;
		defer row.deinit(alloc);
		try std.crypto.pwhash.argon2.strVerify(&row.pass, pass, .{.allocator = alloc}, io);
		return row.id;
	}
};

test {
	const alloc = std.testing.allocator;
	var singleThreaded: std.Io.Threaded = .init_single_threaded;
	const io = singleThreaded.io();

	// db
	var db = try sqlite.Db.init(.{
		.mode = sqlite.Db.Mode{ .Memory = {}},
		.open_flags = .{.write = true, .create = true},
		.threading_mode = .SingleThread,
	});
	var table = Table.init(&db);

	const testPass = "pass";

	// test insert same name fails
	{
		const name = "samename";
		_ = try table.insert(alloc, io, name, testPass);
		try std.testing.expectError(error.SQLiteConstraint, table.insert(alloc, io, name, testPass));
	}

	// test name len
	{
		const maxLen = "a" ** nameMaxLen;
		const maxPlus1Len = "a" ** (nameMaxLen + 1);

		_ = try table.insert(alloc, io, maxLen, testPass);
		try std.testing.expectError(error.SQLiteConstraint, table.insert(alloc, io, maxPlus1Len, testPass));
	}

	// test verifyNamePass
	{
		const name = "verifyNamePass";
		var pass = "a";
		const id = try table.insert(alloc, io, name, pass);
		
		// correct
		try std.testing.expectEqual(id, try table.verifyNamePass(alloc, io, name, pass));

		// incorrect
		pass = "b";
		try std.testing.expectError(error.PasswordVerificationFailed, table.verifyNamePass(alloc, io, name, pass));
	}

	// test delete
	{
		const name = "delete";
		const pass = name;
		const id = try table.insert(alloc, io, name, pass);
		try table.delete(id);
		try std.testing.expectEqual(null, try table.selectId(alloc, id));
	}
}
