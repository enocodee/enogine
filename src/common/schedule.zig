//! Main scheduling of the application that will be run
//! by `World.system_scheduler`
const ecs = @import("../ecs.zig");

const Resource = ecs.query.Resource;
const World = ecs.World;

pub const Label = ecs.schedule.Label;
pub const Graph = ecs.schedule.Graph;
pub const Scheduler = ecs.schedule.Scheduler;

/// All schedule labels are pre-defined in the `ecs`.
pub const schedules = struct {
    /// Start the application
    pub const startup = Label.init("startup");

    /// The main loop of the application
    pub const update = Label.init("update");

    /// Frame deinit
    pub const deinit = Label.init("deinit");
};

const MainScheduleOrder = struct {
    /// Just run once
    startup_labels: []const Label = &[_]Label{
        schedules.startup,
    },
    /// Run multiple times
    labels: []const Label = &[_]Label{
        schedules.update,
        schedules.deinit,
    },
    is_run_once: bool = false,
};

fn run(w: *World, orders_res: Resource(*MainScheduleOrder)) !void {
    const orders = orders_res.result;
    if (!orders.is_run_once) {
        for (orders.startup_labels) |label| {
            try w.runSchedule(label);
        }
        orders.*.is_run_once = true;
    }

    for (orders.labels) |label| {
        try w.runSchedule(label);
    }
}

fn endFrame(w: *World) !void {
    // reset the short-lived allocator
    _ = w.arena.reset(.free_all);
}

/// A standard schedule pre-defined in the application.
/// # Orders:
/// * Run only once the application starts:
/// `startup`
///         |
///         v
/// * Run within the application's main loop:
/// `update` -> `last`
pub const main_schedule_mod = struct {
    pub fn build(w: *ecs.World) void {
        _ = w
            .addSchedule(.system, schedules.startup)
            .addSchedule(.system, schedules.update)
            .addSchedule(.system, schedules.deinit)
            .addResource(MainScheduleOrder, .{})
            .addSystem(.system, Scheduler.entry, run)
            .addSystem(.system, schedules.deinit, endFrame);
    }
};
