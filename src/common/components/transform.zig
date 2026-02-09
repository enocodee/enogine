/// In 2D, `z-axis` is treated as **a depth value**.
/// *Higher* will be at the front.
pub const Transform = struct {
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,

    pub fn fromXYZ(x: i32, y: i32, z: i32) Transform {
        return .{ .x = x, .y = y, .z = z };
    }
};
