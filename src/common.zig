//! Include all common components and some useful systems
const ui = @import("main.zig").ui;

const position = @import("common/components/position.zig");
const grid = @import("common/components/grid/mod.zig");

const rectangle = @import("common/components/rectangle.zig");
const circle = @import("common/components/circle.zig");

pub const raylib = @import("raylib");
pub const raygui = @import("raygui");

pub const schedule = @import("common/schedule.zig");
pub const schedules = schedule.schedules;

const World = @import("ecs.zig").World;

// Shape components
pub const Rectangle = rectangle.Rectangle;
pub const Circle = circle.Circle;
pub const CircleBundle = circle.Bundle;

// Other components
pub const Grid = grid.Grid;
pub const InGrid = grid.InGrid;
pub const Position = position.Position;
pub const Text = @import("common/components/Text.zig");
pub const TextBundle = Text.Bundle;

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
                @import("render.zig").schedule_mod,
            })
            .addModules(&.{
                ui,
                @import("camera.zig").CameraModule,
            })
            .addSystemsWithConfig(.render, schedules.update, .{
            rectangle.render,
            grid.render,
            circle.render,
            Text.render,
        }, .{ .in_sets = &.{@import("render.zig").RenderSet} });
    }
};
