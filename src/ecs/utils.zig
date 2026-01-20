const std = @import("std");

/// Return the child type of `T` if it is a pointer.
pub fn Deref(comptime T: type) type {
    return if (@typeInfo(T) == .pointer) std.meta.Child(T) else T;
}
