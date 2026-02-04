const std    = @import("std");
const sqlite = @import("sqlite");
const util = @import("./util.zig");

pub const tableName = "fileStorePerms";

const createTable = "create table if not exists " ++ tableName ++ " (" ++
	\\    fsId   INTEGER  NOT NULL,
	\\    userId INTEGER  NOT NULL,
	\\    ts     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	\\    ttl    u64,
	\\
	\\    ins BOOLEAN  NOT NULL,
	\\    sel BOOLEAN  NOT NULL,
	\\    upd BOOLEAN  NOT NULL,
	\\    del BOOLEAN  NOT NULL
	\\
	// TODO test
	\\    PRIMARY KEY(fsId, userId)
	\\    UNIQUE(fsId, userId)
	\\)
;

pub const Row = struct {
	fsId:   u64, // fileStore.Id
	userId: u64, // users.Id
	ts:     u64,
	ttl:   ?u64,

	ins: bool,
	sel: bool,
	upd: bool,
	del: bool,
};

pub const Insert = struct {
	fsId:   u64, // fileStore.Id
	userId: u64, // users.Id
	ttl:   ?u64,

	ins: bool,
	sel: bool,
	upd: bool,
	del: bool,
};

pub const Table = struct {
	const Self = @This();

	db: *sqlite.Db,

	pub fn init(db: *sqlite.Db) Self {
		util.mustCreateTable(db, tableName, createTable);
		return .{.db = db};
	}

	pub fn insert(self: *Self, insert: Insert) !void {
		return self.db.exec(
			"INSERT INTO " ++ tableName ++ " (fsId, userId, ttl, ins, sel, upd, del) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
			.{},
			.{insert.fsId, insert.userId, insert.ttl, insert.ins, insert.sel, insert.upd, insert.del},
		);
	}

	pub fn selectFsUser(self: *Self, fsId: u64, userId: u64) !?Row {
		return self.db.one(Row, "SELECT * FROM " ++ tableName ++ " WHERE fsId = (?1) AND userId = (?2)", .{}, .{fsId, userId});
	}

	pub fn delete(self: *Self, fsId: u64, userId: u64) !void {
		return self.db.exec("DELETE FROM " ++ tableName ++ " WHERE fsId = (?1) AND userId = (?2)", .{}, .{fsId, userId});
	}
};
