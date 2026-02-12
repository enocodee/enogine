const ecs = @import("../../../ecs.zig");
const rl = @import("raylib");

const World = ecs.World;
const Resource = ecs.query.Resource;
const Grid = @import("components.zig").Grid;
const Transform = @import("../transform.zig").Transform;
const QueryToRender = @import("../../utils.zig").QueryToRender;
const RenderQueue = @import("../../../render.zig").RenderQueue;

pub fn addRenderToQueue(
    queries: QueryToRender(&.{
        Transform,
        ecs.Entity.ID,
        ecs.query.With(&.{Grid}),
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

pub fn render(w: *World, entity_id: ecs.Entity.ID) !void {
    const grid = (try w.entity(entity_id).getComponents(&.{Grid}))[0];

    switch (grid.render_mode) {
        .line => renderGridLine(grid),
        .block => renderGridBlock(grid),
        .none => {},
    }
}

pub fn renderGrid(queries: QueryToRender(&.{Grid})) !void {
    for (queries.many()) |q| {
        const grid = q[0];

        switch (grid.render_mode) {
            .line => renderGridLine(grid),
            .block => renderGridBlock(grid),
            .none => {},
        }
    }
}

fn renderGridBlock(grid: Grid) void {
    for (grid.matrix) |cell| {
        rl.drawRectangle(
            @intCast(cell.x),
            @intCast(cell.y),
            @intCast(grid.cell_width),
            @intCast(grid.cell_height),
            grid.color,
        );
    }
}

fn renderGridLine(grid: Grid) void {
    const rows: usize = @intCast(grid.num_of_rows);
    const cols: usize = @intCast(grid.num_of_cols);

    // draw vertical lines
    for (0..rows) |i| {
        const idx_x1 = cols * i;
        const idx_y1 = cols * (i + 1) - 1;

        rl.drawLine(
            grid.matrix[idx_x1].x,
            grid.matrix[idx_x1].y,
            grid.matrix[idx_y1].x,
            grid.matrix[idx_y1].y,
            grid.color,
        );
    }

    // draw horizontal lines
    for (0..cols) |i| {
        const idx_x1 = i;
        const idx_y1 = cols * (rows - 1) + i;

        rl.drawLine(
            grid.matrix[idx_x1].x,
            grid.matrix[idx_x1].y,
            grid.matrix[idx_y1].x,
            grid.matrix[idx_y1].y,
            grid.color,
        );
    }
}
