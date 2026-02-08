const eno = @import("eno");
const scheds = eno.common.schedules;
const rl = eno.common.raylib;

const Query = eno.ecs.query.Query;
const World = eno.ecs.World;
const Camera2D = eno.common.raylib.Camera2D;
const CircleBundle = eno.common.CircleBundle;
const Transform = eno.common.Transform;

const VELOCITY = 10;

pub fn build(w: *World) void {
    _ = w
        .addSystem(.system, scheds.startup, spawn)
        .addSystems(.system, scheds.update, &.{ movement, updateCam });
}

fn spawn(w: *World) !void {
    _ = w.spawnEntity(.{
        CircleBundle{
            .circle = .{
                .color = .red,
                .radius = 10,
            },
            .transform = .fromXYZ(
                50,
                50,
                1, // layer 1, this entity should be rendered at front of the map
            ),
        },
        Camera2D{
            .offset = .{
                .x = @floatFromInt(@divTrunc(rl.getScreenWidth(), 2)),
                .y = @floatFromInt(@divTrunc(rl.getScreenHeight(), 2)),
            },
            .target = .{ .x = 50, .y = 50 },
            .rotation = 0,
            .zoom = 1,
        },
    });
}

fn updateCam(q: Query(&.{ *rl.Camera2D, Transform })) !void {
    const cam: *rl.Camera2D, const pos: Transform = q.single();
    cam.target = .{ // follow the player
        .x = @floatFromInt(pos.x),
        .y = @floatFromInt(pos.y),
    };
}

fn movement(player_pos_q: Query(&.{*Transform})) !void {
    const player_pos: *Transform = player_pos_q.single()[0];

    if (rl.isKeyPressed(.j) or rl.isKeyPressedRepeat(.j))
        player_pos.y -= VELOCITY;
    if (rl.isKeyPressed(.k) or rl.isKeyPressedRepeat(.k))
        player_pos.y += VELOCITY;

    if (rl.isKeyPressed(.h) or rl.isKeyPressedRepeat(.h))
        player_pos.x += VELOCITY;
    if (rl.isKeyPressed(.l) or rl.isKeyPressedRepeat(.l))
        player_pos.x -= VELOCITY;
}
