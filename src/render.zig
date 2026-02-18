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
    pub const init = ScheduleLabel.init("init");
    /// Prepare needed information (render queue) for
    /// the `process_render` schedule
    pub const prepare = ScheduleLabel.init("prepare");
    /// This schedule draw all renderable component
    pub const process_render = ScheduleLabel.init("process_render");
    pub const deinit = ScheduleLabel.init("deinit");

    /// This is not intended, just implement for handling ordering & rendering
    /// for the ui and non-ui components.
    /// All render system that are executed after the `end_cam` schedule
    /// will be pinned on the screen.
    ///
    /// TODO: find another way
    pub const begin_cam = ScheduleLabel.init("begin_cam");
    pub const end_cam = ScheduleLabel.init("end_cam");
    pub const ui_process_render = ScheduleLabel.init("ui_process_render");
};

const RenderScheduleOrder = struct {
    /// Run multiple times
    labels: []const ScheduleLabel = &[_]ScheduleLabel{
        schedules.init,
        schedules.prepare,
        schedules.begin_cam,
        schedules.process_render,
        schedules.end_cam,
        schedules.ui_process_render,
        schedules.deinit,
    },
};

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
            .addSchedule(.render, schedules.init)
            .addSchedule(.render, schedules.prepare)
            .addSchedule(.render, schedules.process_render)
            .addSchedule(.render, schedules.deinit)
            .addResource(RenderScheduleOrder, .{})
            .addResource(RenderQueue, .init(w.alloc, {}))
            .configureSet(
                .render,
                schedules.prepare,
                UiRenderSet,
                .{ .after = &.{RenderSet} },
            )
            .addSystem(.render, Scheduler.entry, render)
            .addSystem(.render, schedules.process_render, processRender);

        _ = w
            .addSchedule(.render, schedules.begin_cam)
            .addSchedule(.render, schedules.end_cam)
            .addSchedule(.render, schedules.ui_process_render);
    }
};
