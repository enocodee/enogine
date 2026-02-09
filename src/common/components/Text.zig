const rl = @import("raylib");

const ecs = @import("../../ecs.zig");
const World = ecs.World;
const Resource = ecs.query.Resource;
const RenderQueue = @import("../../render.zig").RenderQueue;
const QueryToRender = @import("../utils.zig").QueryToRender;
const Transform = @import("transform.zig").Transform;

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
    transform: Transform,
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

pub fn render(w: *World, e_id: ecs.Entity.ID) !void {
    const text, const _transform =
        try w
            .entity(e_id)
            .getComponents(&.{ Text, Transform });

    rl.drawTextEx(
        text.font,
        text.content.value(),
        .{
            .x = @floatFromInt(_transform.x),
            .y = @floatFromInt(_transform.y),
        },
        text.size,
        1,
        text.color,
    );
}

pub fn addRenderToQueue(
    queries: QueryToRender(&.{
        Transform,
        ecs.Entity.ID,
        ecs.query.With(&.{Text}),
    }),
    render_queue: Resource(*RenderQueue),
) !void {
    for (queries.many()) |query| {
        const transform, const entity_id = query;

        try render_queue.result.add(.{
            .render_fn = render,
            .entity_id = entity_id,
            .depth = transform.z,
        });
    }
}
