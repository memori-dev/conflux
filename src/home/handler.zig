const std  = @import("std");
const zap  = @import("zap");
const Authentication = @import("../auth.zig");
const util           = @import("../util.zig");
const WelcomeHandler = @import("../welcome/handler.zig");

const html = util.htmlTemplate("home");

const Self = @This();
pub const Path = "/home";

path: []const u8 = Path,
error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

alloc: std.mem.Allocator,
io: std.Io,
auth: Authentication,

pub fn get(self: *Self, req: zap.Request) !void {
	// send home if logged in
	if (self.auth.reqHasValidCookie(self.alloc, self.io, req)) {
		req.setStatus(.ok);
		return req.sendBody(html);
	}

	// redirect to welcome if not logged in
	return req.redirectTo(WelcomeHandler.Path, null);
}
