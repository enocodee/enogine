const components = @import("../ui.zig").components;
const ecs = @import("../ecs.zig");

const World = ecs.World;
const Query = ecs.query.Query;

pub fn QueryUiToRender(comptime types: []const type) type {
    return struct {
        const TypedQuery = Query(types ++ &[_]type{components.Style});
        result: TypedQuery.Result = .{},

        const Self = @This();

        /// This function is the same with `World.query()`, but it
        /// return `null` if one of the storage of `components` not found.
        ///
        /// Used to extract all components of an entity and ensure they are
        /// existed to render.
        pub fn query(self: *Self, w: *const World) !void {
            var obj: TypedQuery = .{};
            if (obj.query(w)) {
                self.result = obj.result;
            } else |err| {
                switch (err) {
                    World.GetComponentError.StorageNotFound => {}, // ignore
                    else => return err,
                }
            }
        }

        pub fn many(self: Self) []TypedQuery.Tuple {
            return self.result.many();
        }

        pub fn single(self: Self) ?TypedQuery.Tuple {
            return self.result.singleOrNull();
        }
    };
}
