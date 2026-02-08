const std = @import("std");

pub fn build(b: *std.Build) void {
    const t = b.standardTargetOptions(.{});
    const o = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "basic-window-example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = t,
            .optimize = o,
        }),
    });

    const eno = b.dependency("eno", .{}).module("eno");
    exe.root_module.addImport("eno", eno);
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the application");
    const run_exe = b.addRunArtifact(exe);
    run_step.dependOn(&run_exe.step);
}
