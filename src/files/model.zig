const std    = @import("std");
const sqlite = @import("sqlite");
const path = @import("../disk/path.zig");
const util = @import("../util.zig");

pub const tableName = "files";

const createTable = "create table if not exists " ++ tableName ++ " (" ++
	\\   id     INTEGER  NOT NULL PRIMARY KEY,
	\\   fsId   INTEGER  NOT NULL,
	\\   parent INTEGER,
	\\   ts     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	\\
	\\   name     TEXT     NOT NULL,
	\\   created  DATETIME NOT NULL,
	\\   size     INTEGER  NOT NULL,
	\\   blake3   TEXT     NOT NULL,
	\\   complete BOOLEAN  NOT NULL DEFAULT 0,
	\\   trash    BOOLEAN  NOT NULL DEFAULT 0
	\\
	// TODO test
	\\   CHECK(id >= 0)
	\\   CHECK(LENGTH(name) <= 128)
	\\   CHECK(LENGTH(blake3) == 44)
	\\)
;

pub const Id = path.uPath;

pub const Insert = struct {
	const Self = @This();

	fsId:    u32,
	parent: ?Id,

	name:     []const u8,
	created:  u64,
	size:     u64,
	blake3:   [44]u8,

	pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
		alloc.free(self.name);
	}
};

pub const Row = struct {
	id:      Id,
	fsId:    u32,
	parent: ?Id,
	ts:      u64,

	name:     []const u8,
	created:  u64,
	size:     u64,
	blake3:   [44]u8,
	complete: bool,
	trash:    bool,
};

pub const Table = struct {
	const Self = @This();

	db:     *sqlite.Db,
	latest: std.atomic.Value(Id),

	pub fn init(db: *sqlite.Db) Self {
		util.mustCreateTable(db, tableName, createTable);
		return .{.db = db, .latest = util.latestId(Id, db, tableName)};
	}

	pub fn insert(self: *Self, data: Insert) !Id {
		const id = self.latest.fetchAdd(1, .seq_cst);
		try self.db.exec(
			"INSERT INTO " ++ tableName ++ " (id, fsId, parent, name, created, size, blake3) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
			.{},
			.{id, data.fsId, data.parent, data.name, data.created, data.size, data.blake3},
		);
		return id;
	}

	pub fn select(self: *Self, id: Id) !?Row {
		return self.db.one(Row, "SELECT * FROM " ++ tableName ++ " WHERE id = (?1) LIMIT 1", .{}, .{id});
	}

	pub fn updateComplete(self: *Self, id: Id) !void {
		try self.db.exec("UPDATE " ++ tableName ++ " SET COMPLETE = true WHERE id = (?1)", .{}, .{id});
	}

	pub fn delete(self: *Self, id: Id) !void {
		return self.db.exec("DELETE FROM " ++ tableName ++ " WHERE id = (?1)", .{}, .{id});
	}
};
