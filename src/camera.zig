const common_utils = @import("common/utils.zig");
const scheds = @import("render.zig").schedules;
const rl = @import("common.zig").raylib;

const World = @import("ecs.zig").World;

pub const CameraModule = struct {
    pub fn build(w: *World) void {
        _ = w
            // this is setup for 2d camera in raylib
            // TODO: add 3d-camera
            .addSystem(.render, scheds.begin_cam, beginCam)
            .addSystem(.render, scheds.end_cam, endCam);
    }
};

fn beginCam(q: common_utils.QueryToRender(&.{rl.Camera2D})) !void {
    for (q.many()) |cam| {
        cam[0].begin();
    }
}

fn endCam(q: common_utils.QueryToRender(&.{rl.Camera2D})) !void {
    for (q.many()) |cam| {
        cam[0].end();
    }
}
