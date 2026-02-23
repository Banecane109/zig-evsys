const std = @import("std");
const zig_evsys = @import("zig_evsys");

const Event = @import("event-system/event.zig").Event;

pub fn main() !void {
    const user: User = try User.init("Random Guy");

    try user.on_player_kick.subscribe(null, on_player_kick_1);
    try user.on_player_kick.subscribe(null, on_player_kick_2);

    try user.kick();
}

fn on_player_kick_1(_: ?*anyopaque, _: void) void {
    std.debug.print("Player is being kicked out (Sub 1)!!!\n", .{});
}

fn on_player_kick_2(_: ?*anyopaque, _: void) void {
    std.debug.print("Player is being kicked out (Sub 2)!!!\n", .{});
}

const User = struct {
    const Self = @This();

    // Events
    on_player_kick: *Event(void),

    // Other Info
    name: []const u8,

    pub fn init(name: []const u8) !Self {
        return .{ .on_player_kick = try Event(void).init(), .name = name };
    }

    pub fn kick(self: Self) !void {
        std.debug.print("Player is being kicked out!!!\n", .{});
        try self.on_player_kick.fire({});
    }
};
