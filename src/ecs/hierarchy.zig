const std = @import("std");
const EntityID = @import("Entity.zig").ID;

pub const Children = struct {
    ids: std.ArrayList(EntityID),

    pub fn deinit(self: *Children, alloc: std.mem.Allocator) void {
        self.ids.deinit(alloc);
    }
};
