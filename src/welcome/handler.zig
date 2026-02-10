const std = @import("std");
const zap = @import("zap");
const Authentication = @import("../auth.zig");
const HomeHandler    = @import("../home/handler.zig");
const util           = @import("../util.zig");

const html = util.htmlTemplate("welcome");

const Self = @This();
pub const Path = "/welcome";

path: []const u8 = Path,
error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

alloc: std.mem.Allocator,
io: std.Io,
auth: Authentication,

pub fn get(self: *Self, req: zap.Request) !void {
	// send home if logged in
	if (self.auth.reqHasValidCookie(self.alloc, self.io, req)) return req.redirectTo(HomeHandler.Path, null);

	// send welcome
	try req.sendBody(html);
	req.setStatus(.ok);
}
