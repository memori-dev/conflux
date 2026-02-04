const std  = @import("std");
const zap  = @import("zap");
const auth    = @import("../auth.zig");
const util    = @import("../util.zig");
const welcome = @import("../welcome/handlers.zig");

const html = @embedFile("../frontend/html/home.html");

pub const Home = struct {
	const Self = @This();
	pub const Path = "/home";

	path: []const u8 = Self.Path,
	error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

	alloc:   std.mem.Allocator,
	io:      std.Io,
	auth:    auth.Authentication,

	pub fn get(self: *Self, req: zap.Request) !void {
		req.parseCookies(false);
		const cookieOpt = req.getCookieStr(self.alloc, self.auth.cookieName)
			catch return util.sendBody(req, .internal_server_error, "failed parsing cookie");

		// send home if logged in
		if (cookieOpt) |cookie| {
			defer self.alloc.free(cookie);
			if (self.auth.isValid(self.alloc, self.io, cookie, self.auth.ttl)) {
				req.setStatus(.ok);
				return req.sendBody(html);
			}
		}

		// redirect to welcome if not logged in
		return req.redirectTo(welcome.Welcome.Path, null);
	}
};
