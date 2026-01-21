const rl = @import("raylib");

const QueryToRender = @import("../utils.zig").QueryToRender;
const Position = @import("position.zig").Position;

const Text = @This();

font: rl.Font,
size: f32,
content: Content,
color: rl.Color,

pub const Content = union(enum) {
    allocated: [:0]const u8,
    str: [:0]const u8,

    pub fn value(self: Content) [:0]const u8 {
        switch (self) {
            .allocated, .str => |str| return str,
        }
    }
};

pub const Bundle = struct {
    text: Text,
    pos: Position,
};

/// See `initWithDefaultFont` to initialize the instace with
/// default font from raylib.
pub fn init(font: rl.Font, content: Content, color: rl.Color, size: f32) Text {
    return .{
        .font = font,
        .content = content,
        .color = color,
        .size = size,
    };
}

pub fn deinit(
    self: Text,
    alloc: @import("std").mem.Allocator,
) void {
    switch (self.content) {
        .allocated => |str| alloc.free(str),
        else => {},
    }
}

pub fn initWithDefaultFont(content: Content, color: rl.Color, size: f32) !Text {
    return .{
        .content = content,
        .font = try rl.getFontDefault(),
        .color = color,
        .size = size,
    };
}

pub fn render(queries: QueryToRender(&.{ Text, Position })) !void {
    for (queries.many()) |query| {
        const text, const pos = query;

        rl.drawTextEx(
            text.font,
            text.content.value(),
            .{ .x = @floatFromInt(pos.x), .y = @floatFromInt(pos.y) },
            text.size,
            1,
            text.color,
        );
    }
}
