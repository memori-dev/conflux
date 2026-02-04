const std    = @import("std");
const sqlite = @import("sqlite");
const util   = @import("../util.zig");

pub const tableName = "filePerms";

const createTable = "create table if not exists " ++ tableName ++ " (" ++
	\\    fileId INTEGER  NOT NULL,
	\\    userId INTEGER  NOT NULL,
	\\    ts     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	\\    ttl    INTEGER,
	\\
	\\    sel BOOLEAN  NOT NULL,
	\\    upd BOOLEAN  NOT NULL,
	\\    del BOOLEAN  NOT NULL,
	\\
	// TODO test
	\\    PRIMARY KEY(fileId, userId)
	\\    UNIQUE(fileId, userId)
	\\)
;

pub const Row = struct {
	fileId:  u64,
	userId:  u64,
	ts:      u64,
	ttl:    ?u64,

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

	pub fn insert(self: *Self, fileId: u64, userId: u64, ttl: ?u64, sel: bool, upd: bool, del: bool) !void {
		return self.db.exec(
			"INSERT INTO " ++ tableName ++ " (fileId, userId, ttl, sel, upd, del) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
			.{},
			.{fileId, userId, ttl, sel, upd, del},
		);
	}

	// TODO check ttl
	pub fn select(self: *Self, fileId: u64, userId: u64) !?Row {
		return self.db.one(Row, "SELECT * FROM " ++ tableName ++ " WHERE fileId = (?1) AND userId = (?2)", .{}, .{fileId, userId});
	}

	pub fn delete(self: *Self, fileId: u64, userId: u64) !void {
		return self.db.exec("DELETE FROM " ++ tableName ++ " WHERE fileId = (?1) AND userId = (?2)", .{}, .{fileId, userId});
	}
};

test {
	var db = try sqlite.Db.init(.{
		.mode = sqlite.Db.Mode{ .Memory = {} },
		.open_flags = .{.write = true, .create = true},
		.threading_mode = .SingleThread,
	});

	_ = Table.init(&db);
}
