// Btree is slower than straight array search probably due to overhead of constructiong BTree everytime
// and the number of numbers to search is higher than the numbers in the tree.
// Ring queue was fun to implement
const std = @import("std");
const assert = @import("assert.zig").assert;
const time_function_error = @import("chrono.zig").time_function_error;
const BTree = @import("btree.zig").BTree;
const RingQueueStatic = @import("ring_queue.zig").RingQueueStatic;

const test_str =
    \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
    \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
    \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
    \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
    \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
    \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    \\
;

fn problem4_part1(data: []const u8, allocator: std.mem.Allocator) !u32 {
    const semi_colon = std.mem.indexOfScalar(u8, data, ':') orelse unreachable;
    const pipe = std.mem.indexOfScalar(u8, data, '|') orelse unreachable;

    var lines = std.mem.splitScalar(u8, data, '\n');

    // var number_tree = BTree(u8).init(allocator);
    var total: u32 = 0;

    // var i: u32 = 0;
    var winners = std.ArrayList(u8).init(allocator);
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        var numbers = std.mem.splitScalar(u8, line[semi_colon + 1 .. pipe], ' ');
        var num_winning: u5 = 0;
        // var num_winning_2: u5 = 0;
        while (numbers.next()) |num| {
            if (num.len == 0 or num[0] == ' ') continue;
            const winning_num = try std.fmt.parseInt(u8, num, 10);
            // try number_tree.insert(winning_num);
            try winners.append(winning_num);
        }

        numbers = std.mem.splitScalar(u8, line[pipe + 1 ..], ' ');
        while (numbers.next()) |num| {
            if (num.len == 0 or num[0] == ' ') continue;
            const trial = try std.fmt.parseInt(u8, num, 10);
            // const in_tree = number_tree.find(trial);
            // if (in_tree) {
            //     num_winning += 1;
            // }

            for (winners.items) |w| {
                if (trial == w) {
                    num_winning += 1;
                    break;
                }
            }
        }
        if (num_winning > 0) {
            total += @as(u32, @intCast(1)) << (num_winning - 1);
        }
        // number_tree.clear();
        winners.shrinkRetainingCapacity(0);
        // i += 1;
        // break;
    }
    // std.debug.print("Number of cards: {d}\n", .{i});
    return total;
}

fn problem4_part2(data: []const u8, allocator: std.mem.Allocator) !u32 {
    const semi_colon = std.mem.indexOfScalar(u8, data, ':') orelse unreachable;
    const pipe = std.mem.indexOfScalar(u8, data, '|') orelse unreachable;
    const new_line = std.mem.indexOfScalar(u8, data, '\n') orelse unreachable;

    const num_lines: u32 = @intCast(@divFloor(data.len, new_line) + 1);

    var lines = std.mem.splitScalar(u8, data, '\n');

    var rqueue = RingQueueStatic(u32, 256){};

    // var number_tree = BTree(u8).init(allocator);
    var total: u32 = 0;
    var curr_num_cards: u32 = 0;
    _ = rqueue.enqueue_many(num_lines, 1);

    // var i: u32 = 0;
    var winners = std.ArrayList(u8).init(allocator);
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        var numbers = std.mem.splitScalar(u8, line[semi_colon + 1 .. pipe], ' ');
        var num_winning: u5 = 0;
        // var num_winning_2: u5 = 0;
        while (numbers.next()) |num| {
            if (num.len == 0 or num[0] == ' ') continue;
            const winning_num = try std.fmt.parseInt(u8, num, 10);
            // try number_tree.insert(winning_num);
            try winners.append(winning_num);
        }

        numbers = std.mem.splitScalar(u8, line[pipe + 1 ..], ' ');
        while (numbers.next()) |num| {
            if (num.len == 0 or num[0] == ' ') continue;
            const trial = try std.fmt.parseInt(u8, num, 10);
            // const in_tree = number_tree.find(trial);
            // if (in_tree) {
            //     num_winning += 1;
            // }

            for (winners.items) |w| {
                if (trial == w) {
                    num_winning += 1;
                    break;
                }
            }
        }
        curr_num_cards = rqueue.dequeue();
        if (num_winning > 0) {
            const len = rqueue.len;
            if (len < num_winning) {
                _ = rqueue.enqueue_many(num_winning - len, 0);
            }
            rqueue.increment_values(num_winning, curr_num_cards);
        }
        if (rqueue.len == 0) {
            _ = rqueue.enqueue(1);
        }
        // number_tree.clear();
        total += curr_num_cards;
        winners.shrinkRetainingCapacity(0);
        // std.debug.print("{d}\n", .{rqueue.items});
        // i += 1;
        // break;
    }
    // std.debug.print("Number of cards: {d}\n", .{i});
    return total;
}

test "problem4_part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const total = try problem4_part1(test_str, allocator);
    std.debug.print("Total test: {d}\n", .{total});

    const file = try std.fs.cwd().openFile(
        "src/problem4.txt",
        .{},
    );
    defer file.close();
    try file.seekTo(0);
    var buffer: [102400]u8 = undefined;
    const data = try file.reader().readAll(&buffer);
    const total2 = try problem4_part1(buffer[0..data], allocator);
    const time = try time_function_error(problem4_part1, .{ buffer[0..data], allocator });
    std.debug.print("Time to run problem3 part2: {d}\n", .{std.fmt.fmtDuration(time)});
    std.debug.print("Problem4 part1: {d}\n", .{total2});
}

test "problem4_part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const total = try problem4_part2(test_str, allocator);
    std.debug.print("Total test: {d}\n", .{total});

    const file = try std.fs.cwd().openFile(
        "src/problem4.txt",
        .{},
    );
    defer file.close();
    try file.seekTo(0);
    var buffer: [102400]u8 = undefined;
    const data = try file.reader().readAll(&buffer);
    const total2 = try problem4_part2(buffer[0..data], allocator);
    const time = try time_function_error(problem4_part2, .{ buffer[0..data], allocator });
    std.debug.print("Time to run problem3 part2: {d}\n", .{std.fmt.fmtDuration(time)});
    std.debug.print("Problem4 part2: {d}\n", .{total2});
}
