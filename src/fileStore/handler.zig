const std    = @import("std");
const json   = @import("json");
const zap    = @import("zap");
const sqlite = @import("sqlite");
const model          = @import("./model.zig");
const util           = @import("../util.zig");
const Authentication = @import("../auth.zig");

fn deinitRows(alloc: std.mem.Allocator, rows: []model.Row) void {
	for (rows) |*row| row.deinit(alloc);
	alloc.free(rows);
}

const Self = @This();
pub const Path = "/fileStore";

path: []const u8 = Path,
error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

alloc: std.mem.Allocator,
io: std.Io,
fileStoreTable: *model.Table,
auth: Authentication,

// TODO filtering
// TODO fileStorePerms to load others with access
pub fn get(self: *Self, req: zap.Request) !void {
	// get user id
	const userId = self.auth.getId(self.alloc, self.io, req)
		catch return util.sendBody(req, .unauthorized, "not logged in");

	// select
	const fileStores = self.fileStoreTable.selectRowsByOwner(self.alloc, userId)
		catch return util.sendBody(req, .internal_server_error, "failed to select in fileStore table");
	defer deinitRows(self.alloc, fileStores);

	// stringify
	const payload = util.payloadToJson(self.alloc, fileStores)
		catch return util.sendBody(req, .internal_server_error, "failed to marshal fileStores");
	defer self.alloc.free(payload);

	return util.sendJson(req, .ok, payload);
}

pub fn post(self: *Self, req: zap.Request) !void {
	// parse name
	const name = req.body
		orelse return util.sendBody(req, .bad_request, "body was empty");

	// get user id
	const userId = self.auth.getId(self.alloc, self.io, req)
		catch return util.sendBody(req, .unauthorized, "not logged in");

	// insert
	const id = self.fileStoreTable.insert(self.io, userId, name)
		catch return util.sendBody(req, .internal_server_error, "failed to insert in fileStore table");

	var buf: [10]u8 = undefined;
	return util.sendBody(req, .ok, std.fmt.bufPrint(&buf, "{d}", .{id}) catch unreachable);
}
