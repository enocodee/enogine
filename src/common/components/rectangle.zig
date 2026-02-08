const rl = @import("raylib");
const ecs = @import("../../ecs.zig");

const World = ecs.World;
const RenderQueue = @import("../../render.zig").RenderQueue;
const Resource = ecs.query.Resource;
const Transform = @import("transform.zig").Transform;
const QueryToRender = @import("../utils.zig").QueryToRender;

pub const Rectangle = struct {
    width: i32,
    height: i32,
    color: rl.Color,
};

pub fn render(w: *World, e_id: ecs.Entity.ID) !void {
    const rec, const _transform =
        try w
            .entity(e_id)
            .getComponents(&.{ Rectangle, Transform });

    rl.drawRectangle(
        _transform.x,
        _transform.y,
        rec.width,
        rec.height,
        rec.color,
    );
}

pub fn addRenderToQueue(
    queries: QueryToRender(&.{ Transform, ecs.Entity.ID, Rectangle }),
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
