const std = @import("std");

pub fn assert(condition: bool, comptime message: ?[]const u8, args: anytype) void {
    if (!condition) {
        if (message) |m| {
            std.debug.print(m, args);
        }
        unreachable;
    }
}

pub fn quick_assert(condition: bool) void {
    if (!condition) {
        unreachable;
    }
}
