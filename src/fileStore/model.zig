const std    = @import("std");
const sqlite = @import("sqlite");

const util  = @import("../util.zig");
const users = @import("../users/model.zig");

pub const tableName = "fileStore";
pub const maxNameLen = 256;

const createTable = "create table if not exists " ++ tableName ++ " (" ++ \\
	\\    id     INTEGER  NOT NULL PRIMARY KEY,
	\\    owner  INTEGER  NOT NULL,
	\\    name   TEXT     NOT NULL,
	\\    ts     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
	// TODO test
	\\    CHECK(LENGTH(name) <= 256)
	\\)
;

const Id = u32;

pub const Row = struct {
	const Self = @This();

	id:     Id,
	owner:  users.Id,
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

	pub fn insert(self: *Self, io: std.Io, owner: users.Id, name: []const u8) !Id {
		const rand = std.Random.IoSource{.io = io};
		const id = rand.interface().int(Id);

		try self.db.exec("INSERT INTO " ++ tableName ++ " (id, owner, name) VALUES (?1, ?2, ?3)", .{}, .{id, owner, name});
		
		return id;
	}

	pub fn select(self: *Self, id: Id) !?Row {
		return self.db.one(Row, "SELECT * FROM " ++ tableName ++ " WHERE id = (?1) LIMIT 1", .{}, .{id});
	}

	pub fn selectOwner(self: *Self, alloc: std.mem.Allocator, owner: users.Id) ![]Row {
		var stmt = try self.db.prepare("SELECT * FROM " ++ tableName ++ " WHERE owner = (?1)");
		defer stmt.deinit();
		return stmt.all(Row, alloc, .{}, .{owner});
	}

	pub fn delete(self: *Self, id: Id) !void {
		return self.db.exec("DELETE FROM " ++ tableName ++ " WHERE id = (?1)", .{}, .{id});
	}
};
