const std  = @import("std");
const zap  = @import("zap");
const auth = @import("auth");
const users = @import("./users/model.zig");

pub const Authenticator = auth.Authenticator(users.Id);

pub const Authentication = struct {
	const Self = @This();

	authenticator: Authenticator,
	cookieName: []const u8,
	ttl: u64,

	pub fn isValid(self: Self, alloc: std.mem.Allocator, io: std.Io, cookie: []const u8, ttl: u64) bool {
		return if (self.authenticator.Validate(alloc, io, cookie, ttl)) true
			else |_| false;
	}

	pub fn setCookie(self: Self, req: zap.Request, cookie: []const u8) !void {
		return req.setCookie(.{
			.name      = self.cookieName,
			.value     = cookie,
			.max_age_s = @intCast(self.ttl),
			.secure    = false, // TODO fix when tls enabled
		});
	}
};
