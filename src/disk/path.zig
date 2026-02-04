const std = @import("std");

pub const basePath = "./conflux/fs";

const fileChars = "abcdefghijk01234";
const dirChars = "pqrstuvwxyz56789";
const segmentLen = 4;

// basePath / dir
const fileDirLen = basePath.len + 1 + segmentLen;
// fileDirLen / file
const filePathLen = fileDirLen + 1 + segmentLen;

// 16(chars)^8(len) = 2^4^8 = 2^32
// upper 16 bits are the dir, and lower are the file
pub const uPath = u32;

fn u16ToStr(charSet: *const [16:0]u8, n: u16) [segmentLen]u8 {
	return [4]u8{
		charSet[n >> 12 & 0xF],
		charSet[n >>  8 & 0xF],
		charSet[n >>  4 & 0xF],
		charSet[n & 0xF],
	};
}

fn strTou16(charSet: *const [16:0]u8, str: [segmentLen]u8) u16 {
	var out: u16 = 0;
	var i: u4 = 0;
	while (i < str.len) {
		out += @as(u16, @intCast(std.mem.indexOfScalar(u8, charSet, str[str.len-1-i]).?)) << (i * 4);
		i += 1;
	}

	return out;
}

pub fn isFirstFileInDir(up: uPath) bool {
	return up & 0xFFFF == 0;
}

fn buildPath(up: uPath) [segmentLen]u8 {
	return u16ToStr(dirChars, @intCast((up & 0xFFFF0000) >> 16));
}

fn buildFile(up: uPath) [segmentLen]u8 {
	return u16ToStr(fileChars, @intCast(up & 0xFFFF));
}

pub fn fileDir(up: uPath) [fileDirLen]u8 {
	var buf: [fileDirLen]u8 = undefined;
	_ = std.fmt.bufPrint(&buf, "{s}/{s}", .{basePath, buildPath(up)}) catch unreachable;
	return buf;	
}

pub fn filePath(up: uPath) [filePathLen]u8 {
	var buf: [filePathLen]u8 = undefined;
	_ = std.fmt.bufPrint(&buf, "{s}/{s}/{s}", .{basePath, buildPath(up), buildFile(up)}) catch unreachable;
	return buf;
}

test "path" {
	// TODO test all w parallelization
	var i: u16 = 0;
	while (true) {
		try std.testing.expectEqual(i, strTou16(fileChars, u16ToStr(fileChars, i)));
		if (i == std.math.maxInt(u16)) break;
		i += 32;
	}
}
