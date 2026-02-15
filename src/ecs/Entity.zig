const std = @import("std");
const query_utils = @import("query/utils.zig");

const Children = @import("hierarchy.zig").Children;
const ChildOf = @import("hierarchy.zig").ChildOf;
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

/// Despawn the caller and its children.
pub fn despawnRecursive(self: Entity) !void {
    despawn_children: {
        const children_q = self.getComponents(&.{Children}) catch |err| switch (err) {
            World.GetComponentError.ValueNotFound, World.GetComponentError.StorageNotFound => break :despawn_children,
            else => return err,
        };
        const children: Children = children_q[0];

        for (children.child_ids.items) |child_id| {
            const child_entity = Entity{ .id = child_id, .world = self.world };
            try child_entity.despawnRecursive();
        }
    }

    try self.despawn();
}

pub inline fn despawn(self: Entity) !void {
    try self.world.despawnEntity(self.id);
}

/// Spawn a new entity and return the id
pub fn spawn(self: Entity, components: anytype) Entity {
    const child =
        self
            .world
            .spawnEntity(components);

    _ = child.setComponent(ChildOf, .{ .parent_id = self.id });
    self.pushChild(child.id);
    return child;
}

/// Push a child's id as a component for the parent entity
pub fn pushChild(
    self: Entity,
    child_id: ID,
) void {
    if (self.getComponents(&.{*Children})) |query| {
        const children: *Children = query[0];
        children.*.child_ids.append(self.world.alloc, child_id) catch @panic("OOM");
    } else |err| switch (err) {
        World.GetComponentError.ValueNotFound, World.GetComponentError.StorageNotFound => {
            // init empty first and then append the list to ensure
            // all elements are allocated by the same allocator
            _ = self.setComponent(Children, .{ .child_ids = .empty });
            const children: *Children =
                (self
                    .getComponents(&.{*Children}) catch
                    @panic("OOM") // if this error occurs, maybe its from list allocations in `tuplesFromTypes`.
                )[0];
            children.*.child_ids.append(self.world.alloc, child_id) catch @panic("OOM");
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
