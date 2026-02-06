//! This module setup for render scheduling:
//! - Introduce system sets for rendering including: `RenderSet`, `UiRenderSet`.
//! - Schedules: `startup`, `update`, `deinit` (see `RenderScheduleOrder` for the order)
//!
//! TODO: ordered rendering by depth values (2d-only)
const ecs = @import("ecs.zig");
const rl = @import("raylib");

const World = ecs.World;
const Resource = ecs.query.Resource;
const SystemSet = ecs.system.Set;
const ScheduleLabel = ecs.schedule.Label;
const Scheduler = ecs.schedule.Scheduler;

/// Set of all non-UI components, that should be exected before `UiRenderSet`.
///
/// See `render.UiRenderSet` for UI components
pub const RenderSet = SystemSet{ .name = "render" };

/// Set of all UI components, that should be executed after `RenderSet`.
///
/// See `render.RenderSet` for non-UI components
pub const UiRenderSet = SystemSet{ .name = "ui_render" };

const schedules = struct {
    pub const startup = ScheduleLabel.init("startup");
    pub const update = ScheduleLabel.init("update");
    pub const deinit = ScheduleLabel.init("deinit");
};

const RenderScheduleOrder = struct {
    /// Run multiple times
    labels: []const ScheduleLabel = &[_]ScheduleLabel{
        schedules.startup,
        schedules.update,
        schedules.deinit,
    },
};

// TODO: each render system will add component tuples to
//       the queue.
// pub const RenderItem = struct {
//     render_fn: *anyopaque,
//     depth: i32,
// };
// pub fn compareRI(ctx: void, a: RenderItem, b: RenderItem) std.math.Order {}
// pub const RenderQueue = std.PriorityQueue(RenderItem, void, compareRI);

fn render(
    w: *World,
    orders_res: Resource(*RenderScheduleOrder),
) !void {
    const orders = orders_res.result;

    rl.beginDrawing();
    rl.clearBackground(.white);
    defer rl.endDrawing();

    for (orders.labels) |label| {
        try w.render_scheduler.runSchedule(w.alloc, w, label);
    }
}

pub const schedule_mod = struct {
    pub fn build(w: *World) void {
        _ = w
            .addSchedule(.render, schedules.startup)
            .addSchedule(.render, schedules.update)
            .addSchedule(.render, schedules.deinit)
            .addResource(RenderScheduleOrder, .{})
            .configureSet(
                .render,
                schedules.update,
                UiRenderSet,
                .{ .after = &.{RenderSet} },
            )
            .addSystem(.render, Scheduler.entry, render);
    }
};
