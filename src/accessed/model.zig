const std    = @import("std");
const sqlite = @import("sqlite");
const util   = @import("../util.zig");

pub const tableName = "accessed";

const createTable = "create table if not exists " ++ tableName ++ " (" ++ \\
	\\    id     INTEGER  NOT NULL PRIMARY KEY,
	\\    fileId INTEGER  NOT NULL,
	\\    userId INTEGER  NOT NULL,
	\\    ts     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	\\)
;
