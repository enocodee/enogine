//! This module use `raylib.Texture2D` as a component
const ecs = @import("../../ecs.zig");
const rl = @import("raylib");
const RenderQueue = @import("../../render.zig").RenderQueue;
const World = ecs.World;
const Resource = ecs.query.Resource;
const Transform = @import("transform.zig").Transform;
const QueryToRender = @import("../utils.zig").QueryToRender;

pub const Bundle = struct {
    texture: rl.Texture2D,
    center_pos: Transform,
};

fn render(w: *World, e_id: ecs.Entity.ID) !void {
    const texture, const transform =
        try w
            .entity(e_id)
            .getComponents(&.{ rl.Texture2D, Transform });

    const half_width = @divTrunc(texture.width, 2);
    const half_height = @divTrunc(texture.height, 2);

    rl.drawTexture(
        texture,
        transform.x - half_width,
        transform.y - half_height,
        .white,
    );
}

pub fn addRenderToQueue(
    queries: QueryToRender(&.{ Transform, ecs.Entity.ID, rl.Texture2D }),
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
