const std = @import("std");
const path = @import("./path.zig");

// create file if not exist
fn _create(disk: Disk, up: path.uPath) !std.Io.File {
	return disk.cwd.createFile(disk.io, &path.filePath(up), .{.read = true, .truncate = false, .exclusive = true, .lock = .exclusive});
}

pub const Disk = struct {
	const Self = @This();

	io: std.Io,
	cwd: std.Io.Dir,

	pub fn init(io: std.Io) Self {
		const cwd = std.Io.Dir.cwd();

		cwd.createDir(io, path.basePath, .default_dir) catch |err| switch (err) {
			error.PathAlreadyExists => {},
			else => @panic(@errorName(err)),
		};
		return .{.io = io, .cwd = cwd};
	}

	pub fn create(self: Self, up: path.uPath, _: u64) !std.Io.File {
		// creating a dir should only be necessary for the first file in a dir
		if (path.isFirstFileInDir(up)) self.cwd.createDir(self.io, &path.fileDir(up), .default_dir) catch |err| switch (err) {
			error.PathAlreadyExists => {},
			else => return err,
		};

		return _create(self, up) catch |err| blk: {
			switch (err) {
				// retry if dir is missing
				error.FileNotFound      => try self.cwd.createDir(self.io, &path.fileDir(up), .default_dir),
				error.PathAlreadyExists => return self.openWrite(up),
				else => return err,
			}
			break :blk try _create(self, up);
		};

		// TODO this is giving OPNOTSUPP on linux with fallocate
		// taken from https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L1804
		//while (true) switch (std.os.linux.errno(std.os.linux.fallocate(file.handle, 0o666, 0, @intCast(size)))) {
			//.SUCCESS   => break,
			//.BADF      => return error.FileDescriptorInvalid,
			//.FBIG      => return error.FileTooBig,
			//.INTR      => continue,
			//.INVAL     => return error.ArgumentsInvalid,
			//.IO        => return error.InputOutput,
			//.NODEV     => return error.NoDevice,
			//.NOSPC     => return error.NoSpaceLeft,
			//.NOSYS     => return error.SystemOutdated,
			//.OPNOTSUPP => return error.OperationNotSupported,
			//.PERM      => return error.PermissionDenied,
			//.SPIPE     => return error.Unseekable,
			//.TXTBSY    => return error.FileBusy,
			//else => {
				// TODO log errno
				//return error.UnexpectedErrnoFallocating;
			//},
		//};

		//return file;
	}

	pub fn openRead(self: Self, up: path.uPath) !std.Io.File {
		// TODO should lock be shared?
		return self.cwd.openFile(self.io, &path.filePath(up), .{.allow_directory = false, .lock = .exclusive});
	}

	pub fn openWrite(self: Self, up: path.uPath) !std.Io.File {
		return self.cwd.openFile(self.io, &path.filePath(up), .{.mode = .write_only, .allow_directory = false, .lock = .exclusive});
	}

	// TODO delete()
};
