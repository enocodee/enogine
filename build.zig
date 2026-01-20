const std = @import("std");

pub fn build(b: *std.Build) !void {
    const t = b.standardTargetOptions(.{});
    const o = b.standardOptimizeOption(.{});

    const common_enabled = b.option(bool, "common", "Add `common` module");
    const ui_enabled = b.option(bool, "ui", "Add `ui` module");
    const all_enabled = common_enabled == null and ui_enabled == null;

    const actual_common_enabled = all_enabled or (common_enabled != null and common_enabled.?);
    const actual_ui_enabled = all_enabled or (common_enabled != null and common_enabled.?);

    const build_opts = b.addOptions();
    build_opts.addOption(bool, "common", actual_common_enabled);
    build_opts.addOption(bool, "ui", actual_ui_enabled);

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = t,
        .optimize = o,
    });
    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const eno = b.addModule("eno", .{
        .root_source_file = b.path("src/main.zig"),
        .target = t,
        .optimize = o,
        .imports = &.{
            .{ .name = "build_config", .module = build_opts.createModule() },
            .{ .name = "raylib", .module = raylib },
            .{ .name = "raygui", .module = raygui },
        },
    });
    eno.linkLibrary(raylib_artifact);

    {
        const test_exe = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = t,
                .optimize = o,
            }),
            .test_runner = .{
                .mode = .simple,
                .path = b.path("test_runner.zig"),
            },
        });
        const run_test_step = b.step("test", "Run unit tests");
        const run_test = b.addRunArtifact(test_exe);
        test_exe.linkLibrary(raylib_artifact);
        test_exe.root_module.addImport("raylib", raylib);
        test_exe.root_module.addImport("raygui", raygui);
        test_exe.root_module.addImport("build_config", build_opts.createModule());

        run_test_step.dependOn(&run_test.step);
    }
}
