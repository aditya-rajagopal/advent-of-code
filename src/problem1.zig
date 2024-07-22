const std = @import("std");
const testing = std.testing;
const time_function_error = @import("chrono.zig").time_function_error;

const test_str =
    \\two1nine
    \\eightwothree
    \\abcone2threexyz
    \\xtwone3four
    \\4nineeightseven2
    \\zoneight234
    \\7pqrstsixteen
;

fn problem1_part1(data: []const u8) !u32 {
    var total: u32 = 0;
    var is_first: bool = true;
    var last_digit: u8 = 0;

    for (data) |ch| {
        switch (ch) {
            '\n' => {
                total += @intCast(last_digit);
                last_digit = 0;
                is_first = true;
            },
            't' => {},
            else => {
                const digit = is_digit(ch);
                if (digit) {
                    if (is_first) {
                        last_digit = @intCast(ch - '0');
                        total += @as(u32, @intCast(last_digit)) * 10;
                        is_first = false;
                    } else {
                        last_digit = @intCast(ch - '0');
                    }
                }
            },
        }
    }
    total += @intCast(last_digit);
    return total;
}

fn is_digit(ch: u8) bool {
    if ('0' <= ch and ch <= '9') {
        return true;
    }
    return false;
}

test "output_part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    _ = allocator;
    const file = try std.fs.cwd().openFile(
        "src/problem1.txt",
        .{},
    );
    defer file.close();
    try file.seekTo(0);
    var buffer: [102400]u8 = undefined;
    const data = try file.reader().readAll(&buffer);

    var total = try problem1_part1(test_str);
    // std.debug.print("Total test: {d}\n", .{total});
    total = try problem1_part1(buffer[0..data]);
    const time = try time_function_error(problem1_part1, .{buffer[0..data]});
    std.debug.print("Time to run problem1 part1: {d}\n", .{std.fmt.fmtDuration(time)});
    std.debug.print("Problem1 part1: {d}\n", .{total});
}
