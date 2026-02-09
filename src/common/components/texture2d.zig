const ecs = @import("../../ecs.zig");
const rl = @import("raylib");
const RenderQueue = @import("../../render.zig").RenderQueue;
const World = ecs.World;
const Resource = ecs.query.Resource;
const Transform = @import("transform.zig").Transform;
const QueryToRender = @import("../utils.zig").QueryToRender;

pub const Texture2D = rl.Texture2D;

fn render(w: *World, e_id: ecs.Entity.ID) !void {
    const texture, const transform =
        try w
            .entity(e_id)
            .getComponents(&.{ Texture2D, Transform });

    rl.drawTexture(texture, transform.x, transform.y, .white);
}

pub fn addRenderToQueue(
    queries: QueryToRender(&.{ Transform, ecs.Entity.ID, Texture2D }),
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
