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
    \\eightthree8fiveqjgsdzgnnineeight
    \\eightwo
    \\one
;

const numbers = std.ComptimeStringMap(u32, .{
    .{ "one", 1 },
    .{ "two", 2 },
    .{ "three", 3 },
    .{ "four", 4 },
    .{ "five", 5 },
    .{ "six", 6 },
    .{ "seven", 7 },
    .{ "eight", 8 },
    .{ "nine", 9 },
    .{ "1", 1 },
    .{ "2", 2 },
    .{ "3", 3 },
    .{ "4", 4 },
    .{ "5", 5 },
    .{ "6", 6 },
    .{ "7", 7 },
    .{ "8", 8 },
    .{ "9", 9 },
});

fn problem1_part2(data: []const u8) !u32 {
    var total: u32 = 0;
    var is_first: bool = true;
    var last_digit: u8 = 0;

    var lines = std.mem.split(u8, data, "\n");
    var buffer: [4096]u8 = undefined;
    var i: usize = 0;
    while (lines.next()) |line| {
        var first_num_loc: i32 = @intCast(line.len + 1);
        var first_num: u32 = 0;
        var last_num_loc: i32 = -1;
        var last_num: u32 = 0;
        @memcpy(buffer[0..line.len], line);
        std.mem.reverse(u8, buffer[0..line.len]);
        const reverse_line = buffer[0..line.len];

        for (numbers.kvs) |number| {
            if (std.mem.lastIndexOf(u8, line, number.key)) |val| {
                // std.debug.print("Found: {s} at {d}\n", .{ number.key, val });
                if (val > last_num_loc) {
                    last_num_loc = @intCast(val);
                    last_num = number.value;
                }
            }
            const reverse_key = buffer[line.len .. line.len + number.key.len];
            @memcpy(reverse_key, number.key);
            std.mem.reverse(u8, reverse_key);
            if (std.mem.lastIndexOf(u8, reverse_line, reverse_key)) |val| {
                const loc = line.len - val - number.key.len;
                // std.debug.print("Found Reverse: {s} at {d}\n", .{ number.key, loc });
                if (loc < first_num_loc) {
                    first_num_loc = @intCast(loc);
                    first_num = number.value;
                }
            }
        }

        total += first_num * 10 + last_num;
        last_digit = 0;
        is_first = true;
        // std.debug.print("Line[{d}]: {s}, [{d}{d}] \r\n", .{ i, line, first_num, last_num });
        i += 1;
    }

    return total;
}

fn is_digit(ch: u8) bool {
    if ('0' <= ch and ch <= '9') {
        return true;
    }
    return false;
}

test "output_part2" {
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

    var total = try problem1_part2(test_str);
    // std.debug.print("Total test: {d}\n", .{total});
    total = try problem1_part2(buffer[0..data]);
    // std.debug.print("Total Actual: {d}\n", .{total});
    const time = try time_function_error(problem1_part2, .{buffer[0..data]});
    std.debug.print("Time to run problem1 part2: {d}\n", .{std.fmt.fmtDuration(time)});
    std.debug.print("Problem1 part2: {d}\n", .{total});
}
