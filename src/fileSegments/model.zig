const std    = @import("std");
const sqlite = @import("sqlite");

const files  = @import("../files/model.zig");
const util   = @import("../util.zig");

pub const tableName = "fileSegments";

pub const segmentSize = 8 * 1024 * 1024;

const createTable = "create table if not exists " ++ tableName ++ " (" ++ \\
	\\   fileId INTEGER  NOT NULL,
	\\   idx    INTEGER  NOT NULL,
	\\   blake3 BLOB     NOT NULL,
	\\
	// TODO test
	\\   PRIMARY KEY(fileId, idx)
	\\   CHECK(LENGTH(blake3) == 44)
	\\)
;

pub const Row = struct {
	fileId: files.Id,
	idx:    u32,
	blake3: [44]u8,
};

pub const Insert = Row;

pub const Table = struct {
	const Self = @This();

	db: *sqlite.Db,

	pub fn init(db: *sqlite.Db) Self {
		util.mustCreateTable(db, tableName, createTable);
		return .{.db = db};
	}

	pub fn insert(self: *Self, data: Insert) !void {
		return self.db.exec("INSERT INTO " ++ tableName ++ " (fileId, idx, blake3) VALUES (?1, ?2, ?3)", .{}, .{data.fileId, data.idx, data.blake3});
	}

	pub fn count(self: *Self, id: u64) !?u64 {
		return self.db.one(u64, "SELECT COUNT(*) FROM " ++ tableName ++ " WHERE id = (?1)", .{}, .{id});
	}

	pub fn select(self: *Self, id: u64) !?Row {
		return self.db.one(Row, "SELECT * FROM " ++ tableName ++ " WHERE id = (?1) LIMIT 1", .{}, .{id});
	}

	pub fn selectBlake3(self: *Self, fileId: files.Id, idx: u64) !?[44]u8 {
		return self.db.one([44]u8, "SELECT blake3 FROM " ++ tableName ++ " WHERE fileId = (?1) AND idx = (?2)", .{}, .{fileId, idx});
	}

	pub fn selectIdxBlake3(self: *Self, alloc: std.mem.Allocator, idx: u64) ![]Row {
		var stmt = try self.db.prepare("SELECT * FROM " ++ tableName ++ " WHERE idx = (?1)");
		defer stmt.deinit();
		return stmt.all(Row, alloc, .{}, .{idx});
	}

	pub fn delete(self: *Self, fileId: files.Id, idx: u64) !void {
		return self.db.exec("DELETE FROM " ++ tableName ++ " WHERE fileId = (?1) AND idx = (?2)", .{}, .{fileId, idx});
	}
};
