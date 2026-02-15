//! This module contains all types related to relationship
//! between entities following the model of one parent to
//! many children. (1 - M)
const std = @import("std");
const EntityID = @import("Entity.zig").ID;

const World = @import("World.zig");
const ErasedComponentStorage = @import("component.zig").ErasedStorage;

/// A container that contains all children ids.
pub const Children = struct {
    child_ids: std.ArrayList(EntityID),

    pub fn deinit(self: *Children, alloc: std.mem.Allocator) void {
        self.child_ids.deinit(alloc);
    }
};

/// A container that contains the parent id of
/// a children entity.
pub const ChildOf = struct {
    parent_id: EntityID,
};

/// Remove the relationship between a child and its
/// parent.
///
/// The the parent's children storage will be **removed** if
/// the number of items is **less than 1** *after* removing the
/// specified children, otherwise, the function only removes the
/// children id of in list of children.
pub fn unrelated(w: *World, child_id: EntityID) !void {
    if (w
        .entity(child_id)
        .getComponents(&.{ChildOf})) |child_of_q|
    {
        const parent_id = child_of_q[0].parent_id;
        // It is impossible for an entity to have `ChildOf`
        // but not exists in any children storages.
        const children_storage = ErasedComponentStorage.cast(w, Children) catch unreachable;
        // It is impossible for an children entity to have `parent_id`
        // that is not exists in any children storages.
        const children: *Children = children_storage.data.getPtr(parent_id) orelse unreachable;
        std.debug.assert(children.child_ids.items.len > 0);

        if (children.child_ids.items.len == 1) {
            // remove the children storage if there are
            // no more elements left
            children.deinit(w.alloc);
            _ = children_storage.data.remove(parent_id);
        } else {
            // SAFETY: assigned during searching
            var removed_i: usize = undefined;
            for (children.child_ids.items, 0..) |c_id, i| {
                if (c_id == child_id) {
                    removed_i = i;
                    break;
                }
            } else unreachable;

            _ = children.child_ids.swapRemove(removed_i);
        }
    } else |err| switch (err) {
        std.mem.Allocator.Error.OutOfMemory => return err,
        else => {}, // ignore ValueNotFound, StorageNotFound
    }
}
