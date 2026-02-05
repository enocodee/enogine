const build_config = @import("build_config");

pub const ecs = @import("ecs.zig");
pub const camera = @import("camera.zig");
pub const render = @import("render.zig");
pub const common = if (build_config.common) @import("common.zig") else struct {};
pub const ui = if (build_config.ui) @import("ui.zig") else struct {};

pub const window = struct {
    const rl = @import("raylib");

    pub fn init(width: i32, height: i32, title: [:0]const u8) void {
        rl.initWindow(width, height, title);
    }

    pub fn deinit() void {
        rl.closeWindow();
    }

    pub fn shouldClose() bool {
        return rl.windowShouldClose();
    }

    pub fn screenWidth() u32 {
        return @intCast(rl.getScreenWidth());
    }

    pub fn screenHeight() i32 {
        return @intCast(rl.getScreenWidth());
    }
};

test {
    _ = ecs;
    _ = common;
    _ = ui;
}
