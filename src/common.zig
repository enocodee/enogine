//! Include all common components and some useful systems
const render = @import("render.zig");
const ui = @import("main.zig").ui;

const transform = @import("common/components/transform.zig");
const grid = @import("common/components/grid/mod.zig");

const rectangle = @import("common/components/rectangle.zig");
const circle = @import("common/components/circle.zig");

pub const raylib = @import("raylib");
pub const raygui = @import("raygui");

pub const schedule = @import("common/schedule.zig");
pub const schedules = schedule.schedules;

pub const render_schedules = render.schedules;

const World = @import("ecs.zig").World;

// Shape components
pub const Rectangle = rectangle.Rectangle;
pub const Circle = circle.Circle;
pub const CircleBundle = circle.Bundle;

// Other components
pub const Grid = grid.Grid;
pub const InGrid = grid.InGrid;
pub const Transform = transform.Transform;
pub const Text = @import("common/components/Text.zig");
pub const TextBundle = Text.Bundle;

// Texture
const texture2d = @import("common/components/texture2d.zig");
pub const Texture2D = texture2d.Texture2D;

// TODO: remove all api from raylib

/// * Add the main scheduling.
/// * Add the render scheduling.
/// * Extract & render systems for common components
/// automatically.
pub const CommonModule = struct {
    pub fn build(w: *World) void {
        _ = w
            .addModules(&.{
                schedule.main_schedule_mod,
                render.schedule_mod,
            })
            .addModules(&.{
                ui,
                @import("camera.zig").CameraModule,
            })
            .addSystemsWithConfig(
            .render,
            render_schedules.update,
            .{ // TODO: Automate the process of adding items to queue
                grid.render,
                rectangle.addRenderToQueue,
                circle.addRenderToQueue,
                texture2d.addRenderToQueue,
                Text.addRenderToQueue,
            },
            .{ .in_sets = &.{render.RenderSet} },
        );
    }
};
