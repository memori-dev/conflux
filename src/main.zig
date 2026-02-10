const std    = @import("std");
const sqlite = @import("sqlite");
const zap    = @import("zap");

const auth = @import("./auth.zig");
const config = @import("./config.zig");
const path = @import("./disk/path.zig");
const Disk = @import("./disk/disk.zig").Disk;
const filePerms = @import("./filePerms/model.zig");
const filesHandlers = @import("./files/handlers.zig");
const files = @import("./files/model.zig");
const fileSegments = @import("./fileSegments/model.zig");

const FileStoreTable    = @import("./fileStore/model.zig").Table;
const fileStoreHandlers = @import("./fileStore/handlers.zig");

const users = @import("./users/model.zig");
const homeHandlers = @import("./home/handlers.zig");
const usersHandlers = @import("./users/handlers.zig");
const welcomeHandlers = @import("./welcome/handlers.zig");

// TODO http header for error sets to allow for exhaustive testing/handling

test {
	std.testing.refAllDecls(@This());
}

fn fallback(r: zap.Request) !void {
	// TODO create page that shows 404
	// TODO redirect based on cookies
	return r.redirectTo("/welcome", null);
}

fn onErr(_: zap.Request, err: anyerror) void {
	std.debug.print("Uncaught err: {}\n", .{err});
}

pub fn main() !void {
	// allocator
	var gpa = std.heap.GeneralPurposeAllocator(.{.thread_safe = true}){};
	defer _ = gpa.detectLeaks();
	const alloc = gpa.allocator();

	// io
	var singleThreaded: std.Io.Threaded = .init_single_threaded;
	const io = singleThreaded.io();

	// sqlite
	var db = try sqlite.Db.init(.{
		.mode = sqlite.Db.Mode{ .File = "./conflux/db/test.sqlite" },
		.open_flags = .{.write = true, .create = true},
		.threading_mode = .MultiThread,
	});

	// server
	var listener = zap.Endpoint.Listener.init(
		alloc,
		.{
			.port = config.port,
			.io = io,
			.on_request = fallback,
			.on_error = onErr,
			.log = true,
			.public_folder = "src/frontend/dist",
		},
	);
	defer listener.deinit();

	// objs/data
	var filesTable = files.Table.init(&db);
	var fileSegmentsTable = fileSegments.Table.init(&db);
	var fileStoreTable = FileStoreTable.init(&db);
	var usersTable = users.Table.init(&db);
	_ = filePerms.Table.init(&db);
	const disk = Disk.init(io);
	const authentication = auth.Authentication {
		.authenticator = auth.Authenticator{.keyPair = @import("auth").testingKeyPair},
		.cookieName = "id",
		.ttl = 60*60*24*90,
	};

	// endpoints
	var filesInit = filesHandlers.Init {.alloc = alloc, .io = io, .disk = disk, .db = &db, .filesTable = &filesTable, .fileSegmentsTable = &fileSegmentsTable};
	try listener.register(&filesInit);

	var filesProgress = filesHandlers.Progress {.alloc = alloc, .fileSegmentsTable = &fileSegmentsTable};
	try listener.register(&filesProgress);

	var filesSegment = filesHandlers.Segment {.alloc = alloc, .io = io, .disk = disk, .filesTable = &filesTable, .fileSegmentsTable = &fileSegmentsTable};
	try listener.register(&filesSegment);

	var fileStore = fileStoreHandlers.FileStore {.alloc = alloc, .io = io, .fileStoreTable = &fileStoreTable, .auth = authentication};
	try listener.register(&fileStore);

	var signup = usersHandlers.Signup {.alloc = alloc, .io = io, .usersTable = &usersTable, .auth = authentication};
	try listener.register(&signup);

	var login = usersHandlers.Login {.alloc = alloc, .io = io, .usersTable = &usersTable, .auth = authentication};
	try listener.register(&login);

	var usersHandler = usersHandlers.Users {.alloc = alloc, .io = io, .usersTable = &usersTable};
	try listener.register(&usersHandler);

	var home = homeHandlers.Home {.alloc = alloc, .io = io, .auth = authentication};
	try listener.register(&home);

	var welcome = welcomeHandlers.Welcome {.alloc = alloc, .io = io, .auth = authentication};
	try listener.register(&welcome);

	// run server
	try listener.listen();
	zap.start(.{.threads = 1, .workers = 1});
}
