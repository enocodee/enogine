//! This module setup for render scheduling:
//! - Introduce system sets for rendering including: `RenderSet`, `UiRenderSet`.
//! - Schedules: `startup`, `update`, `deinit` (see `RenderScheduleOrder` for the order)
//!
//! TODO: ordered rendering by depth values (2d-only)
const std = @import("std");
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

pub const schedules = struct {
    pub const startup = ScheduleLabel.init("startup");
    /// Prepare needed information (render queue) for
    /// the `process_render` schedule
    pub const update = ScheduleLabel.init("update");
    /// This schedule draw all renderable component
    pub const process_render = ScheduleLabel.init("process_render");
    pub const deinit = ScheduleLabel.init("deinit");
};

const RenderScheduleOrder = struct {
    /// Run multiple times
    labels: []const ScheduleLabel = &[_]ScheduleLabel{
        schedules.startup,
        schedules.update,
        schedules.process_render,
        schedules.deinit,
    },
};

// TODO: each render system will add component tuples to
//       the queue.
pub const RenderItem = struct {
    render_fn: *const fn (*World, ecs.Entity.ID) anyerror!void,
    entity_id: ecs.Entity.ID,
    depth: i32,
};

fn compareRI(ctx: void, a: RenderItem, b: RenderItem) std.math.Order {
    _ = ctx;
    if (a.depth == b.depth) {
        return .eq;
    } else if (a.depth < b.depth) {
        return .lt;
    } else if (a.depth > b.depth) {
        return .gt;
    } else {
        unreachable;
    }
}

/// This queue affects **2d components** in the form of layers.
/// In 3D, this queue do nothing (the queue still process, but as usual).
pub const RenderQueue = std.PriorityQueue(RenderItem, void, compareRI);

fn render(
    w: *World,
    orders_res: Resource(*RenderScheduleOrder),
) !void {
    const orders = orders_res.result;

    rl.beginDrawing();
    rl.clearBackground(.white);
    defer rl.endDrawing();

    for (orders.labels) |label| { // Add items into the queue
        try w.render_scheduler.runSchedule(w.alloc, w, label);
    }
}

pub fn processRender(
    w: *World,
    render_queue: Resource(*RenderQueue),
) !void {
    const queue = render_queue.result;
    var iter = queue.iterator();
    while (iter.next()) |item| {
        try item.render_fn(w, item.entity_id);
    }
    queue.clearAndFree(); // reset the queue
}

pub const schedule_mod = struct {
    pub fn build(w: *World) void {
        _ = w
            .addSchedule(.render, schedules.startup)
            .addSchedule(.render, schedules.update)
            .addSchedule(.render, schedules.process_render)
            .addSchedule(.render, schedules.deinit)
            .addResource(RenderScheduleOrder, .{})
            .addResource(RenderQueue, .init(w.alloc, {}))
            .configureSet(
                .render,
                schedules.update,
                UiRenderSet,
                .{ .after = &.{RenderSet} },
            )
            .addSystem(.render, Scheduler.entry, render)
            .addSystem(.render, schedules.process_render, processRender);
    }
};
