const std = @import("std");
const zig_evsys = @import("zig_evsys");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}
