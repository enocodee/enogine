pub const Label = @import("schedule/label.zig").Label;
pub const Graph = @import("schedule/Graph.zig");
pub const Scheduler = @import("schedule/Scheduler.zig");

/// All schedule labels are pre-defined in the `ecs`.
pub const schedules = struct {
    /// Start the application
    pub const startup = Label.init("startup");

    /// The main loop of the application
    pub const update = Label.init("update");

    /// Frame deinit
    pub const deinit = Label.init("deinit");
};
