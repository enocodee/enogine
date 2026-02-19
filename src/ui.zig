const rl = @import("raylib");
const ecs = @import("ecs.zig");
const scheds = @import("render.zig").schedules;

const World = ecs.World;
const Resource = ecs.query.Resource;
const QueryUiToRender = @import("ui/utils.zig").QueryUiToRender;
const RenderQueue = @import("render.zig").RenderQueue;

pub const components = struct {
    /// NOTE: rectangle style only now
    /// This is intended like CSS in the future.
    pub const Style = struct {
        pos: struct {
            x: i32 = 0,
            y: i32 = 0,
        } = .{},
        width: u32 = 50,
        height: u32 = 50,
        bg_color: rl.Color = .blank,
        text: ?struct {
            font: rl.Font,
            content: [:0]const u8,
            x: i32 = 0,
            y: i32 = 0,
        } = null,
        z_index: i32 = 0,
    };
};

fn render(w: *World, entity_id: ecs.Entity.ID) !void {
    const ui_style: components.Style =
        (try w
            .entity(entity_id)
            .getComponents(&.{components.Style}))[0];

    rl.drawRectangle(
        ui_style.pos.x,
        ui_style.pos.y,
        @intCast(ui_style.width),
        @intCast(ui_style.height),
        ui_style.bg_color,
    );

    if (ui_style.text) |txt| {
        rl.drawTextEx(
            txt.font,
            txt.content,
            .{
                .x = @floatFromInt(ui_style.pos.x + txt.x),
                .y = @floatFromInt(ui_style.pos.y + txt.y),
            },
            20,
            1,
            .black,
        );
    }
}

pub fn addRenderToQueue(
    queries: QueryUiToRender(&.{ecs.Entity.ID}),
    render_queue: Resource(*RenderQueue),
) !void {
    for (queries.many()) |query| {
        const entity_id, const style = query;

        try render_queue.result.add(.{
            .render_fn = render,
            .entity_id = entity_id,
            .depth = style.z_index,
        });
    }
}

pub fn processRender(
    w: *World,
    render_queue: Resource(*RenderQueue),
) !void {
    const queue = render_queue.result;

    while (queue.removeOrNull()) |item| {
        try item.render_fn(w, item.entity_id);
    }
}

pub fn build(w: *World) void {
    _ = w
        .addSystem(.render, scheds.ui_prepare, addRenderToQueue)
        .addSystem(.render, scheds.ui_process_render, processRender);
}
