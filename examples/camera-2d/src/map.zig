const eno = @import("eno");
const rl = eno.common.raylib;
const scheds = eno.common.schedules;

const Transform = eno.common.Transform;
const World = eno.ecs.World;

pub fn build(w: *World) void {
    _ = w
        .addSystem(.system, scheds.startup, spawn);
}

fn spawn(w: *World) !void {
    const map_img = try rl.loadImage("assets/map.png");
    _ = w.spawnEntity(&.{
        try eno.common.Texture2D.fromImage(map_img),
        Transform.fromXYZ(
            0,
            0,
            0, // layer 0, this entity should be rendered behind the player
        ),
    });
}
