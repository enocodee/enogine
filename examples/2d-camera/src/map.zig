const eno = @import("eno");
const rl = eno.common.raylib;
const scheds = eno.common.schedules;

const Query = eno.ecs.query.Query;
const World = eno.ecs.World;

pub fn build(w: *World) void {
    _ = w
        .addSystem(.system, scheds.startup, spawn)
        .addSystem(.render, scheds.update, render);
}

fn spawn(w: *World) !void {
    const map_img = try rl.loadImage("assets/map.png");
    _ = w.spawnEntity(&.{
        try rl.Texture2D.fromImage(map_img),
    });
}

fn render(texture_q: Query(&.{rl.Texture2D})) !void {
    rl.drawTexture(texture_q.single()[0], 0, 0, .white);
}
