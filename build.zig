const std = @import("std");

// TODO build js bundles
pub fn build(b: *std.Build) void {
	const target = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{});
	const tarOpt = .{
		.target = target,
		.optimize = optimize,
	};

	const exe_mod = b.createModule(.{
		.root_source_file = b.path("src/main.zig"),
		.target = target,
		.optimize = optimize,
	});

	exe_mod.addImport("auth",   b.dependency("auth",   tarOpt).module("auth"));
	exe_mod.addImport("json",   b.dependency("json",   tarOpt).module("json"));
	exe_mod.addImport("sqlite", b.dependency("sqlite", tarOpt).module("sqlite"));
	const zap = b.dependency("zap", .{
		.target = target,
		.optimize = optimize,
		.openssl = false, // set to true for TLS support
	});
	exe_mod.addImport("zap", zap.module("zap"));

	const exe = b.addExecutable(.{
		.name = "conflux",
		.root_module = exe_mod,
	});

	b.installArtifact(exe);

	const run_cmd = b.addRunArtifact(exe);
	run_cmd.step.dependOn(b.getInstallStep());
	const run_step = b.step("run", "Run the app");
	run_step.dependOn(&run_cmd.step);

	const exe_unit_tests = b.addTest(.{
		.root_module = exe_mod,
		.test_runner = .{
			.path = b.path("src/test_runner.zig"),
			.mode = .simple,
		},
	});

	const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
	const test_step = b.step("test", "Run unit tests");
	test_step.dependOn(&run_exe_unit_tests.step);
}
