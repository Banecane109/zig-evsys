const std = @import("std");

const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayList;

pub fn Event(comptime T: type) type {
    return struct {
        const Self = @This();

        // Definition of callback that is used by Listeners and will be called when event is fired
        pub const Callback = *const fn (context: ?*anyopaque, data: T) void;

        // Struct that defines all subscribed functions
        pub const Listener = struct {
            context: ?*anyopaque,
            func: Callback,
        };

        listeners: ArrayList(Listener),
        arena_allocator: *ArenaAllocator,
        lock: std.Thread.RwLock,

        /// Creates new instance of Event object on heap using arena allocator. <br/>
        pub fn init() !*Self {
            // Initialize arena allocator that will be responsable for all event handler allocations and frees
            const arena: *ArenaAllocator = @constCast(&std.heap.ArenaAllocator.init(std.heap.page_allocator));
            const allocator = arena.allocator();

            // Create new instance of event handler
            const instance: *Self = try allocator.create(Self);
            instance.arena_allocator = arena;
            instance.listeners = try ArrayList(Listener).initCapacity(allocator, 2);
            instance.lock = .{};

            return instance;
        }

        pub fn deinit(self: *Self) !void {
            // First get arena allocator pointer so we dont lose it before deinit
            const arena: *ArenaAllocator = self.arena_allocator;
            const allocator = arena.allocator();

            self.listeners.clearAndFree(allocator);
            self.listeners.deinit(allocator);
            allocator.free(self); // Frees Event instance
            arena.deinit();
        }

        pub inline fn subscribe(self: *Self, contenxt: ?*anyopaque, callback: Callback) !void {
            self.lock.lock();
            defer self.lock.unlock();
            try self.listeners.append(self.arena_allocator.allocator(), Listener{ .context = contenxt, .func = callback });
        }

        pub inline fn unsubscribe(self: *Self, ctx: ?*anyopaque, func: Callback) void {
            self.lock.lock();
            defer self.lock.unlock();

            // Iterate backwards so we can remove items without skipping indices
            var i: usize = self.listeners.items.len;
            inline while (i > 0) {
                i -= 1;
                const listener = self.listeners.items[i];
                if (listener.ctx == ctx and listener.func == func) {
                    _ = self.listeners.orderedRemove(i);
                    break;
                }
            }
        }

        pub inline fn fire(self: *Self, data: T) !void {
            self.lock.lockShared();
            defer self.lock.unlockShared();

            for (self.listeners.items) |listener| {
                listener.func(listener.context, data);
            }
        }
    };
}
