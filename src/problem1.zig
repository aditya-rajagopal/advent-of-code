const std = @import("std");
const testing = std.testing;

const test_str =
    \\two1nine
    \\eightwothree
    \\abcone2threexyz
    \\xtwone3four
    \\4nineeightseven2
    \\zoneight234
    \\7pqrstsixteen
;

const one = "one";
const two = "two";
const three = "three";
const four = "four";
const five = "five";
const six = "six";
const seven = "seven";
const eight = "eight";
const nine = "nine";

fn problem1(data: []const u8) !void {
    var total: u32 = 0;
    var is_first: bool = true;
    var last_digit: u8 = 0;
    const len = data.len;

    for (data, 0..) |ch, i| {
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
    std.debug.print("Total: {d}\n", .{total});
}

fn is_digit(ch: u8) bool {
    if ('0' <= ch and ch <= '9') {
        return true;
    }
    return false;
}

test "output" {
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

    try problem1(test_str);
    try problem1(buffer[0..data]);
}
