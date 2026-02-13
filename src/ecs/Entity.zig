const std = @import("std");
const query_utils = @import("query/utils.zig");

const Children = @import("hierarchy.zig").Children;
const World = @import("World.zig");

const Entity = @This();

id: ID,
world: *World,

pub const ID = usize;

const SpawnChildrenCallback = *const fn (Entity) anyerror!void;

pub fn withChildren(
    self: Entity,
    callback: SpawnChildrenCallback,
) !void {
    try callback(self);
}

/// Spawn a new entity and return the id
pub fn spawn(self: Entity, components: anytype) Entity {
    const child_id =
        self
            .world
            .spawnEntity(components)
            .id;

    self.pushChildren(&[_]ID{child_id});
    return .{ .id = child_id, .world = self.world };
}

/// Push children's entity id as components for the parent entity
pub fn pushChildren(
    self: Entity,
    child_ids: []const ID,
) void {
    if (self.getComponents(&.{*Children})) |query| {
        const children: *Children = query[0];
        children.ids.appendSlice(self.world.alloc, child_ids) catch @panic("OOM");
    } else |err| switch (err) {
        World.GetComponentError.ValueNotFound, World.GetComponentError.StorageNotFound => {
            _ = self.setComponent(Children, .{ .ids = .empty });
            const children: *Children =
                (self
                    .getComponents(&.{*Children}) catch
                    @panic("OOM") // if this error occurs, maybe its from list allocations in `tuplesFromTypes`.
                )[0];
            children.ids.appendSlice(self.world.alloc, child_ids) catch @panic("OOM");
        },
        std.mem.Allocator.Error.OutOfMemory => @panic("OOM"),
    }
}

pub fn getComponents(
    self: Entity,
    comptime types: []const type,
) !std.meta.Tuple(types) {
    return (try query_utils.tuplesFromTypes(
        self.world,
        &.{self.id},
        types,
    ))[0];
}

pub fn setComponent(
    self: Entity,
    comptime T: type,
    value: T,
) Entity {
    self.world.setComponent(self.id, T, value);
    return self;
}
