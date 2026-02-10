const std  = @import("std");
const zap  = @import("zap");
const auth = @import("auth");
const users = @import("./users/model.zig");

// TODO cookie invalidation when req has cookie, but is expired or incorrect

pub const Authenticator = auth.Authenticator(users.Id);

const Self = @This();

authenticator: Authenticator,
cookieName: []const u8,
ttl: u64,

pub fn cookieIsValid(self: Self, alloc: std.mem.Allocator, io: std.Io, cookie: []const u8) bool {
	return if (self.authenticator.Validate(alloc, io, cookie, self.ttl)) true
		else |_| false;
}

pub fn reqHasValidCookie(self: Self, alloc: std.mem.Allocator, io: std.Io, req: zap.Request) bool {
	req.parseCookies(false);
	const cookieOpt = req.getCookieStr(alloc, self.cookieName) catch return false;
	const cookie = cookieOpt orelse return false;
	defer alloc.free(cookie);
	return self.cookieIsValid(alloc, io, cookie);
}

pub fn getId(self: Self, alloc: std.mem.Allocator, io: std.Io, req: zap.Request) !users.Id {
	req.parseCookies(false);
	const cookieOpt = try req.getCookieStr(alloc, self.cookieName);
	const cookie = cookieOpt orelse return error.NoAuthCookie;
	defer alloc.free(cookie);

	const decoded = try self.authenticator.Decode(alloc, io, cookie, self.ttl);
	decoded.deinit();
	return decoded.value;
}

pub fn setCookie(self: Self, req: zap.Request, cookie: []const u8) !void {
	return req.setCookie(.{
		.name      = self.cookieName,
		.value     = cookie,
		.max_age_s = @intCast(self.ttl),
		.secure    = false, // TODO fix when tls enabled
	});
}
