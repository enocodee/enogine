const rl = @import("raylib");
const ecs = @import("../../ecs.zig");

const RenderQueue = @import("../../render.zig").RenderQueue;
const World = ecs.World;
const Resource = ecs.query.Resource;
const Transform = @import("transform.zig").Transform;
const QueryToRender = @import("../utils.zig").QueryToRender;

pub const Bundle = struct {
    circle: Circle,
    transform: Transform,
};

pub const Circle = struct {
    radius: i32,
    color: rl.Color,
};

pub fn render(w: *World, e_id: ecs.Entity.ID) !void {
    const circle, const _transform =
        try w
            .entity(e_id)
            .getComponents(&.{ Circle, Transform });

    rl.drawCircle(
        _transform.x,
        _transform.y,
        @floatFromInt(circle.radius),
        circle.color,
    );
}

pub fn addRenderToQueue(
    queries: QueryToRender(&.{ Transform, ecs.Entity.ID, Circle }),
    render_queue: Resource(*RenderQueue),
) !void {
    for (queries.many()) |query| {
        const transform, const entity_id, _ = query;

        try render_queue.result.add(.{
            .render_fn = render,
            .entity_id = entity_id,
            .depth = transform.z,
        });
    }
}
