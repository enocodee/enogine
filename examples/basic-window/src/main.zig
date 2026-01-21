const std = @import("std");
const eno = @import("eno");

const World = eno.ecs.World;

fn spawn(w: *World) !void {
    _ = w.spawnEntity(.{eno.common.TextBundle{
        .pos = .{ .x = 0, .y = 0 },
        .text = try .initWithDefaultFont(.{ .str = "hehe" }, .black, 20),
    }});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer if (gpa.deinit() == .leak) {
        std.log.err("Memory leaks has been detected in `basic-window` example.", .{});
    };
    const alloc = gpa.allocator();
    var world: World = .init(alloc);
    defer world.deinit();

    eno.window.init(800, 450, "Basic Window");
    defer eno.window.deinit();

    _ = try world
        .addModules(&.{eno.common.CommonModule}) // this is important
        .addSystem(.system, eno.common.schedules.startup, spawn)
        .run();
}
