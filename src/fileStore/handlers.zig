const std    = @import("std");
const json   = @import("json");
const zap    = @import("zap");
const sqlite = @import("sqlite");
const model = @import("./model.zig");
const util  = @import("../util.zig");
const auth  = @import("../auth.zig");

fn deinitRows(alloc: std.mem.Allocator, rows: []model.Row) void {
	for (rows) |*row| row.deinit(alloc);
	alloc.free(rows);
}

pub const FileStore = struct {
	const Self = @This();

	path: []const u8 = "/fileStore",
	error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

	alloc: std.mem.Allocator,
	io: std.Io,
	fileStoreTable: *model.Table,
	auth: auth.Authentication,

	// ?name={d}
	pub fn post(self: *Self, req: zap.Request) !void {
		// parse name
		const name = req.getParamSlice("name")
			orelse return util.sendBody(req, .bad_request, "missing name in query params");

		// get user id
		const userId = self.auth.getId(self.alloc, self.io, req)
			catch return util.sendBody(req, .unauthorized, "not logged in");

		// insert
		const id = self.fileStoreTable.insert(self.io, userId, name)
			catch return util.sendBody(req, .internal_server_error, "failed to insert in fileStore table");

		var buf: [10]u8 = undefined;
		return util.sendBody(req, .ok, std.fmt.bufPrint(&buf, "{d}", .{id}) catch unreachable);
	}

	// TODO filtering
	pub fn get(self: *Self, req: zap.Request) !void {
		// get user id
		const userId = self.auth.getId(self.alloc, self.io, req)
			catch return util.sendBody(req, .unauthorized, "not logged in");

		// select
		const fileStores = self.fileStoreTable.selectOwner(self.alloc, userId)
			catch return util.sendBody(req, .internal_server_error, "failed to select in fileStore table");
		defer deinitRows(self.alloc, fileStores);

		// stringify
		const payload = util.payloadToJson(self.alloc, fileStores)
			catch return util.sendBody(req, .internal_server_error, "failed to marshal fileStores");
		defer self.alloc.free(payload);

		return util.sendJson(req, .ok, payload);
	}

	pub fn postReq(alloc: std.mem.Allocator, cli: *std.http.Client, name: []const u8, cookie: []const u8) !model.Id {
		// todo alloc print
		const uriFmt = "http://localhost:8080/fileStore?name={s}";
		const uri = try std.fmt.allocPrint(alloc, uriFmt, .{name});

		var req = try cli.request(.POST, std.Uri.parse(uri) catch unreachable, .{
			.headers = .{.accept_encoding = .{.override = "gzip, deflate, br, zstd"}},
			.extra_headers = &.{
				.{.name = "Cookie", .value = cookie},
			},
		});
		defer req.deinit();

		try req.sendBodiless();
		var response = try req.receiveHead(&.{});

		util.dumpHeaders(response.head);
		util.dumpHead(response.head);

		// TODO handle status / errors
		return switch (response.head.status) {
			// TODO .ok => try std.fmt.parseInt(),
			.ok => 1,
			else => error.UploadFailed,
		};
	}
};

