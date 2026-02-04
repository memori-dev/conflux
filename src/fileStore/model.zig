const std    = @import("std");
const sqlite = @import("sqlite");
const util = @import("./util.zig");

pub const tableName = "fileStore";

const createTable = "create table if not exists " ++ tableName ++ " (" ++ \\
	\\    id     INTEGER  NOT NULL PRIMARY KEY,
	\\    name   TEXT     NOT NULL,
	\\    ts     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
	\\)
;

pub const Row = struct {
	const Self = @This();

	id:     u64,
	name:   []const u8,
	ts:     u64,

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

	pub fn insert(self: *Self, name: []const u8) !void {
		return self.db.exec("INSERT INTO " ++ tableName ++ " (name) VALUES (?1)", .{}, .{name});
	}

	pub fn select(self: *Self, id: u64) !?Row {
		return self.db.one(Row, "SELECT * FROM " ++ tableName ++ " WHERE id = (?1) LIMIT 1", .{}, .{id});
	}

	pub fn delete(self: *Self, id: u64) !void {
		return self.db.exec("DELETE FROM " ++ tableName ++ " WHERE id = (?1)", .{}, .{id});
	}
};
