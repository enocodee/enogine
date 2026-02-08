const std = @import("std");
const eno = @import("eno");

const player = @import("player.zig");
const map = @import("map.zig");

const World = eno.ecs.World;

fn closeWindow(w: *World) !void {
    if (eno.window.shouldClose()) w.should_exit = true;
}

fn drawFPS() !void {
    eno.common.raylib.drawFPS(0, 0);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer if (gpa.deinit() == .leak) {
        std.log.err("Memory leaks has been detected in `2d-camera` example.", .{});
    };
    const alloc = gpa.allocator();
    var world: World = .init(alloc);
    defer world.deinit();

    eno.window.init(800, 450, "2D Camera");
    defer eno.window.deinit();

    _ = try world
        .addModules(&.{
            eno.common.CommonModule, // this is important
            player,
            map,
        })
        .addSystems(.system, eno.common.schedules.update, &.{ closeWindow, drawFPS })
        .run();
}
