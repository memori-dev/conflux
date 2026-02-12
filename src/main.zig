const std    = @import("std");
const sqlite = @import("sqlite");
const zap    = @import("zap");

const Authentication = @import("./auth.zig");
const config = @import("./config.zig");

const path = @import("./disk/path.zig");
const Disk = @import("./disk/disk.zig").Disk;

const FilePermsTable = @import("./filePerms/model.zig").Table;

const FilesTable = @import("./files/model.zig").Table;
const FilesHandler = @import("./files/handler.zig");

const FileSegmentsTable = @import("./fileSegments/model.zig").Table;
const FileSegmentsHandler = @import("./fileSegments/handler.zig");

const FileStoreTable = @import("./fileStore/model.zig").Table;
const FileStoreHandler = @import("./fileStore/handler.zig");

const UsersTable = @import("./users/model.zig").Table;
const usersHandlers = @import("./users/handlers.zig");

const HomeHandler = @import("./home/handler.zig");
const WelcomeHandler = @import("./welcome/handler.zig");

// TODO http header for error sets to allow for exhaustive testing/handling

test {
	//std.testing.refAllDecls(@This());
	_ = @import("./cli/cli.zig");
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
	var filesTable        = FilesTable.init(&db);
	var fileSegmentsTable = FileSegmentsTable.init(&db);
	var fileStoreTable    = FileStoreTable.init(&db);
	var usersTable        = UsersTable.init(&db);
	//_ = filePerms.Table.init(&db);

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

	// disk
	const disk = Disk.init(io);

	// auth
	const authentication = Authentication {
		.authenticator = .{.keyPair = @import("auth").testingKeyPair},
		.cookieName = "id",
		.ttl = 60*60*24*90,
	};

	// handlers
	var filesHandler = FilesHandler {.alloc = alloc, .io = io, .disk = disk, .auth = authentication, .db = &db, .filesTable = &filesTable, .fileStoreTable = &fileStoreTable, .fileSegmentsTable = &fileSegmentsTable};
	try listener.register(&filesHandler);

	var fileSegmentsHandler = FileSegmentsHandler {.alloc = alloc, .io = io, .disk = disk, .filesTable = &filesTable, .fileSegmentsTable = &fileSegmentsTable};
	try listener.register(&fileSegmentsHandler);

	var fileStoreHandler = FileStoreHandler {.alloc = alloc, .io = io, .fileStoreTable = &fileStoreTable, .auth = authentication};
	try listener.register(&fileStoreHandler);

	var signupHandler = usersHandlers.Signup {.alloc = alloc, .io = io, .usersTable = &usersTable, .auth = authentication};
	try listener.register(&signupHandler);

	var loginHandler = usersHandlers.Login {.alloc = alloc, .io = io, .usersTable = &usersTable, .auth = authentication};
	try listener.register(&loginHandler);

	var usersHandler = usersHandlers.Users {.alloc = alloc, .io = io, .usersTable = &usersTable};
	try listener.register(&usersHandler);

	var homeHandler = HomeHandler {.alloc = alloc, .io = io, .auth = authentication};
	try listener.register(&homeHandler);

	var welcomeHandler = WelcomeHandler {.alloc = alloc, .io = io, .auth = authentication};
	try listener.register(&welcomeHandler);

	// run server
	try listener.listen();
	zap.start(.{.threads = 1, .workers = 1});
}
