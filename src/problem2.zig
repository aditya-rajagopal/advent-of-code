// This is using simd on purpose. Not the fastest possible solution but it was good to learn.
const std = @import("std");
const assert = @import("assert.zig").assert;
const time_function_error = @import("chrono.zig").time_function_error;

const test_str =
    \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
    \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
    \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
    \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
    \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
;

const Bag = @Vector(4, u32);
const test_bag = Bag{ 12, 13, 14, 0 };

const colours = enum(u2) {
    red = 0,
    green = 1,
    blue = 2,
};

pub fn problem2_part1(data: []const u8) !u32 {
    var lines = std.mem.split(u8, data, "\n");
    var round: Bag = Bag{ 0, 0, 0, 0 };
    var total: u32 = 0;

    while (lines.next()) |line| {
        // std.debug.print("{s}\n", .{line});
        var i: u32 = 5;
        var colour: colours = .red;
        var number: u32 = 0;
        var id: u32 = 0;
        var game_fail: bool = false;
        while (i < line.len + 1) {
            const ch = if (i < line.len) line[i] else ';';
            switch (ch) {
                ':' => {
                    id = number;
                    i += 1;
                    number = 0;
                },
                ';' => {
                    round[@intFromEnum(colour)] = number;
                    const result = round > test_bag;
                    const fail = @reduce(.Or, result);
                    if (fail) {
                        game_fail = true;
                        // std.debug.print("[{d}] Round: {any}\n", .{ id, round });
                        // std.debug.print("[{d}] Result: {any}, {any}\n", .{ id, result, fail });
                        round = @splat(0);
                        break;
                    }
                    round = @splat(0);
                    i += 1;
                },
                ',' => {
                    round[@intFromEnum(colour)] = number;
                    i += 1;
                },
                ' ' => i += 1,
                else => {
                    const start = i;
                    while (line[i] != ':' and line[i] != ';' and line[i] != ',' and line[i] != ' ') {
                        i += 1;
                        if (i >= line.len) break;
                    }
                    const end = i;
                    if (line[start] == 'b') {
                        colour = .blue;
                    } else if (line[start] == 'r') {
                        colour = .red;
                    } else if (line[start] == 'g') {
                        colour = .green;
                    } else {
                        number = try std.fmt.parseInt(u32, line[start..end], 10);
                    }
                },
            }
        }
        if (!game_fail) {
            total += id;
        } else {
            game_fail = false;
        }
    }
    return total;
}

pub fn problem2_part2(data: []const u8) !u32 {
    var lines = std.mem.split(u8, data, "\n");
    var round: Bag = Bag{ 0, 0, 0, 1 };
    var max: Bag = Bag{ 0, 0, 0, 1 };
    const reset = Bag{ 0, 0, 0, 1 };
    var total: u32 = 0;

    while (lines.next()) |line| {
        var i: u32 = 5;
        var colour: colours = .red;
        var number: u32 = 0;
        while (i < line.len + 1) {
            const ch = if (i < line.len) line[i] else ';';
            switch (ch) {
                ':' => {
                    i += 1;
                },
                ';' => {
                    round[@intFromEnum(colour)] = number;
                    max = @max(round, max);
                    round = reset;
                    i += 1;
                },
                ',' => {
                    round[@intFromEnum(colour)] = number;
                    i += 1;
                },
                ' ' => i += 1,
                else => {
                    const start = i;
                    while (line[i] != ':' and line[i] != ';' and line[i] != ',' and line[i] != ' ') {
                        i += 1;
                        if (i >= line.len) break;
                    }
                    const end = i;
                    if (line[start] == 'b') {
                        colour = .blue;
                    } else if (line[start] == 'r') {
                        colour = .red;
                    } else if (line[start] == 'g') {
                        colour = .green;
                    } else {
                        number = try std.fmt.parseInt(u32, line[start..end], 10);
                    }
                },
            }
        }
        total += @reduce(.Mul, max);
        max = reset;
    }
    return total;
}

test "problem2_part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    _ = allocator;

    const total = try problem2_part1(test_str);
    std.debug.print("Total test: {d}\n", .{total});

    const file = try std.fs.cwd().openFile(
        "src/problem2.txt",
        .{},
    );
    defer file.close();
    try file.seekTo(0);
    var buffer: [102400]u8 = undefined;
    const data = try file.reader().readAll(&buffer);
    const total2 = try problem2_part1(buffer[0..data]);
    const time = try time_function_error(problem2_part1, .{buffer[0..data]});
    std.debug.print("Time to run problem2 part1: {d}\n", .{std.fmt.fmtDuration(time)});
    std.debug.print("Problem2 part1: {d}\n", .{total2});
}

test "problem2_part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    _ = allocator;

    const total = try problem2_part2(test_str);
    std.debug.print("Total test: {d}\n", .{total});

    const file = try std.fs.cwd().openFile(
        "src/problem2.txt",
        .{},
    );
    defer file.close();
    try file.seekTo(0);
    var buffer: [102400]u8 = undefined;
    const data = try file.reader().readAll(&buffer);
    const total2 = try problem2_part2(buffer[0..data]);
    const time = try time_function_error(problem2_part2, .{buffer[0..data]});
    std.debug.print("Time to run problem2 part2: {d}\n", .{std.fmt.fmtDuration(time)});
    std.debug.print("Problem2 part2: {d}\n", .{total2});
}
