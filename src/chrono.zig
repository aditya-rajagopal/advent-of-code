const std = @import("std");
const Timer = std.time.Timer;

pub fn time_function(func: anytype, args: anytype) u64 {
    var start = Timer.start() catch unreachable;
    _ = @call(.auto, func, args);
    return start.lap();
}

pub fn time_function_error(func: anytype, args: anytype) !u64 {
    var start = Timer.start() catch unreachable;
    _ = try @call(.auto, func, args);
    return start.lap();
}

test "timer" {
    const time = time_function(std.mem.eql, .{ u8, "test", "test" });
    std.debug.print("Time: {d}ns\n", .{time});
}
