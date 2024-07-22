const std = @import("std");
const assert = @import("assert.zig").assert;
const time_function_error = @import("chrono.zig").time_function_error;

const test_str =
    \\467..114..
    \\...*......
    \\..35..633.
    \\......#...
    \\617*......
    \\.....+..58
    \\..592.....
    \\......755.
    \\...$.*....
    \\.664.598..
    \\
;

pub fn problem3_part1(data: []const u8, allocator: std.mem.Allocator) !u32 {
    const w: i32 = @intCast(std.mem.indexOf(u8, data, "\n") orelse 0);
    if (w == 0) {
        return 0;
    }
    const h = @divFloor(@as(i32, @intCast(data.len)), w + 1);

    const mask = try allocator.alloc(u8, data.len);
    @memset(mask, 0);
    defer allocator.free(mask);

    for (0..mask.len) |pos| {
        const ch = data[pos];
        if (!((ch >= '0' and ch <= '9') or ch == '.' or ch == '\n')) {
            const p_2: i32 = @intCast(pos);
            var dx_2: i32 = -1;
            while (dx_2 < 2) : (dx_2 += 1) {
                var dy_2: i32 = -1;
                while (dy_2 < 2) : (dy_2 += 1) {
                    const x_2: i32 = @divFloor(p_2, w + 1) + dx_2;
                    const y_2: i32 = dy_2 + @mod(p_2, w + 1);
                    if (x_2 < 0 or y_2 < 0 or x_2 >= h or y_2 >= w) {
                        continue;
                    }
                    const pos_2: usize = @intCast(x_2 * (w + 1) + y_2);
                    mask[pos_2] = 1;
                }
            }
        }
    }

    var list = try std.ArrayList(u8).initCapacity(allocator, @intCast(w));
    defer list.deinit();

    var number: u32 = 0;
    var to_consider: bool = false;

    var total: u32 = 0;
    for (data, 0..) |ch, i| {
        if (ch >= '0' and ch <= '9') {
            list.appendAssumeCapacity(ch);
            if (mask[i] == 1) {
                to_consider = true;
            }
            continue;
        }

        if (list.items.len > 0) {
            number = try std.fmt.parseInt(u32, list.items, 10);
            list.shrinkRetainingCapacity(0);
            if (to_consider) {
                // std.debug.print("number: {d}\n", .{number});
                total += number;
                number = 0;
                to_consider = false;
            }
        }
    }

    return total;
}

pub fn problem3_part2(data: []const u8, allocator: std.mem.Allocator) !u32 {
    const w: i32 = @intCast(std.mem.indexOf(u8, data, "\n") orelse 0);
    if (w == 0) {
        return 0;
    }
    const h = @divFloor(@as(i32, @intCast(data.len)), w + 1);

    const num1 = try allocator.alloc(u32, data.len);
    @memset(num1, 0);
    defer allocator.free(num1);
    const num2 = try allocator.alloc(u32, data.len);
    @memset(num2, 0);
    defer allocator.free(num2);

    var list = try std.ArrayList(u8).initCapacity(allocator, @intCast(w));
    defer list.deinit();

    // var stars = try std.ArrayList(usize).initCapacity(allocator, @intCast(w * 2 + 2));
    // defer stars.deinit();

    var stars = std.AutoHashMap(usize, void).init(allocator);
    defer stars.deinit();

    var number: u32 = 0;

    for (data, 0..) |ch, i| {
        if (ch >= '0' and ch <= '9') {
            list.appendAssumeCapacity(ch);
            try find_all_star(data, &stars, i, w, h);
            continue;
        }

        if (list.items.len > 0) {
            number = try std.fmt.parseInt(u32, list.items, 10);
            list.shrinkRetainingCapacity(0);
            var star_iter = stars.keyIterator();
            while (star_iter.next()) |s| {
                const star_loc = s.*;
                if (num1[star_loc] == 0 and num2[star_loc] == 0) {
                    num1[star_loc] = number;
                } else if (num2[star_loc] == 0) {
                    num2[star_loc] = number;
                } else {
                    num1[star_loc] = 0;
                }
            }
            stars.clearRetainingCapacity();
            number = 0;
        }
    }
    var total: u32 = 0;
    for (num1, num2) |n1, n2| {
        total += n1 * n2;
    }
    return total;
}

fn find_all_star(data: []const u8, stars: *std.AutoHashMap(usize, void), pos: usize, w: i32, h: i32) !void {
    const p: i32 = @intCast(pos);
    var dx: i32 = -1;
    while (dx < 2) : (dx += 1) {
        var dy: i32 = -1;
        while (dy < 2) : (dy += 1) {
            const x: i32 = @divFloor(p, w + 1) + dx;
            const y: i32 = dy + @mod(p, w + 1);
            if (x < 0 or y < 0 or x >= h or y >= w) {
                continue;
            }
            const pos_star: usize = @intCast(x * (w + 1) + y);
            if (data[pos_star] == '*') {
                try stars.put(pos_star, {});
            }
        }
    }
}

test "problem3_part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const total = try problem3_part1(test_str, allocator);
    std.debug.print("Total test: {d}\n", .{total});

    const file = try std.fs.cwd().openFile(
        "src/problem3.txt",
        .{},
    );
    defer file.close();
    try file.seekTo(0);
    var buffer: [102400]u8 = undefined;
    const data = try file.reader().readAll(&buffer);
    const total2 = try problem3_part1(buffer[0..data], allocator);
    const time = try time_function_error(problem3_part1, .{ buffer[0..data], allocator });
    std.debug.print("Time to run problem3 part1: {d}\n", .{std.fmt.fmtDuration(time)});
    std.debug.print("Problem3 part1: {d}\n", .{total2});
}

test "problem3_part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const total = try problem3_part2(test_str, allocator);
    std.debug.print("Total test: {d}\n", .{total});

    const file = try std.fs.cwd().openFile(
        "src/problem3.txt",
        .{},
    );
    defer file.close();
    try file.seekTo(0);
    var buffer: [102400]u8 = undefined;
    const data = try file.reader().readAll(&buffer);
    const total2 = try problem3_part2(buffer[0..data], allocator);
    const time = try time_function_error(problem3_part2, .{ buffer[0..data], allocator });
    std.debug.print("Time to run problem3 part2: {d}\n", .{std.fmt.fmtDuration(time)});
    std.debug.print("Problem3 part2: {d}\n", .{total2});
}
