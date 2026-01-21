const component = @import("ecs/component.zig");

pub const ErasedComponentStorage = component.ErasedStorage;
pub const ComponentStorage = component.Storage;
pub const World = @import("ecs/World.zig");
pub const Entity = @import("ecs/Entity.zig");

pub const utils = @import("ecs/utils.zig");

pub const schedule = struct {
    pub const Label = @import("ecs/schedule/label.zig").Label;
    pub const Graph = @import("ecs/schedule/Graph.zig");
    pub const Scheduler = @import("ecs/schedule/Scheduler.zig");
};

pub const query = struct {
    const _query = @import("ecs/query.zig");
    pub const utils = @import("ecs/query/utils.zig");

    pub const Query = _query.Query;
    pub const QueryError = _query.QueryError;

    // filter
    pub const With = _query.filter.With;
    pub const Without = _query.filter.Without;

    pub const Resource = @import("ecs/resource.zig").Resource;
};

pub const system = struct {
    const _system = @import("ecs/system.zig");

    pub const Set = _system.Set;
    pub const System = _system.System;
};

test {
    @import("std").testing.refAllDeclsRecursive(@This());
}
