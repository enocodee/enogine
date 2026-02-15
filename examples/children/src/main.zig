/// This example show how to spawn children of an entity and
/// it can be recursive.
///
/// After using `world.spawnEntity()`, the function will return a
/// value of type `Entity` and we can use its `withChildren()` to
/// spawn children in a callback.
const std = @import("std");
const eno = @import("eno");
const ecs = eno.ecs;
const common = eno.common;
const rl = common.raylib;

const World = ecs.World;
const Entity = ecs.Entity;
const Children = ecs.hierarchy.Children;

const Transform = common.Transform;
const TextBundle = common.TextBundle;

const Query = eno.ecs.query.Query;
const With = eno.ecs.query.With;

const NodeData = struct {
    name: [:0]const u8,
    offset_x: i32,
    offset_y: i32,
    children: []const NodeData,
};

const children: []const NodeData = &.{
    .{ .name = "B", .offset_x = 50, .offset_y = 50, .children = &.{
        .{ .name = "C", .offset_x = 50, .offset_y = 50, .children = &.{} },
        .{ .name = "F", .offset_x = 100, .offset_y = 50, .children = &.{} },
        .{ .name = "G", .offset_x = 150, .offset_y = 50, .children = &.{} },
    } },
    .{ .name = "E", .offset_x = -50, .offset_y = 50, .children = &.{
        .{ .name = "D", .offset_x = 50, .offset_y = 50, .children = &.{} },
    } },
};

const Node = struct {};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer if (gpa.deinit() == .leak) {
        std.log.err("Memory leaks has been detected in `children` example.", .{});
    };
    const alloc = gpa.allocator();
    var world: World = .init(alloc);
    defer world.deinit();

    eno.window.init(800, 450, "Children Example");
    defer eno.window.deinit();

    _ = try world
        .addModules(&.{eno.common.CommonModule}) // this is important
        .addSystem(.system, eno.common.schedules.startup, spawn)
        .addSystems(.system, eno.common.schedules.update, &.{
            closeWindow,
            onHover,
            onClicked,
        })
        .addSystem(.render, eno.common.schedules.update, drawRelationship)
        .run();
}

pub fn closeWindow(w: *World) !void {
    if (eno.window.shouldClose()) w.should_exit = true;
}

fn spawn(w: *World) !void {
    const half_screen_width = @divTrunc(rl.getScreenWidth(), 2);
    const half_screen_height = @divTrunc(rl.getScreenHeight(), 2);

    _ = w.spawnEntity(&.{
        TextBundle{
            .text = try .initWithDefaultFont(.{ .str = "Click on a node to despawn" }, .gray, 30),
            .transform = .fromXYZ(100, 100, 0),
        },
    });

    try w.spawnEntity(.{
        Node{},
        TextBundle{
            .transform = .fromXYZ(half_screen_width, half_screen_height, 0),
            .text = try .initWithDefaultFont(.{ .str = "A" }, .black, 20),
        },
    }).withChildren(struct {
        pub fn spawnChildren(parent: Entity) !void {
            try recursiveSpawnChildren(parent, children);
        }

        fn recursiveSpawnChildren(parent: Entity, _children: []const NodeData) !void {
            const parent_transform = (try parent.getComponents(&.{Transform}))[0];
            for (_children) |child| {
                const entity = parent.spawn(&.{
                    Node{},
                    TextBundle{
                        .transform = .fromXYZ(
                            parent_transform.x + child.offset_x,
                            parent_transform.y + child.offset_y,
                            0,
                        ),
                        .text = try .initWithDefaultFont(.{ .str = child.name }, .black, 20),
                    },
                });

                try recursiveSpawnChildren(entity, child.children);
            }
        }
    }.spawnChildren);
}

fn onHover(
    text_q: Query(&.{
        Transform,
        *common.Text,
        With(&.{Node}),
    }),
) !void {
    for (text_q.many()) |query| {
        const transform, const text = query;
        const mouse_pos = rl.getMousePosition();
        if (rl.checkCollisionPointRec(mouse_pos, .{
            .x = @floatFromInt(transform.x),
            .y = @floatFromInt(transform.y),
            .width = text.size,
            .height = text.size,
        })) {
            text.size = 30;
        } else {
            text.size = 20;
        }
    }
}

fn onClicked(
    w: *World,
    text_q: Query(&.{
        Transform,
        *common.Text,
        Entity.ID,
        With(&.{Node}),
    }),
) !void {
    for (text_q.many()) |query| {
        const transform, const text, const entity_id = query;
        const mouse_pos = rl.getMousePosition();
        if (rl.isMouseButtonPressed(.left)) {
            if (rl.checkCollisionPointRec(mouse_pos, .{
                .x = @floatFromInt(transform.x),
                .y = @floatFromInt(transform.y),
                .width = text.size,
                .height = text.size,
            })) {
                try w.entity(entity_id).despawnRecursive();
            }
        }
    }
}

fn drawRelationship(
    w: *World,
    children_q: Query(&.{
        Children,
        Transform,
        With(&.{Node}),
    }),
) !void {
    for (children_q.many()) |query| {
        const children_container, const parent_transform = query;
        for (children_container.child_ids.items) |c_id| {
            const children_transform =
                (try w
                    .entity(c_id)
                    .getComponents(&.{Transform}))[0];

            rl.drawLine(
                parent_transform.x + 10,
                parent_transform.y + 20,
                children_transform.x,
                children_transform.y,
                .red,
            );
        }
    }
}
