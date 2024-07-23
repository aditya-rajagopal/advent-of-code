const std = @import("std");

pub fn BTree(comptime T: type) type {
    return struct {
        backing: std.MultiArrayList(Node),
        root: ?NodeIndex,
        allocator: std.mem.Allocator,

        const Self = @This();

        const NodeIndex = usize;
        pub const Node = struct {
            height: u32 = 1,
            value: T,
            left_child: ?NodeIndex = null,
            right_child: ?NodeIndex = null,
        };

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .root = null, .backing = .{}, .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.backing.deinit(self.allocator);
        }

        fn get_height(items: []u32, node: ?NodeIndex) i32 {
            if (node) |n| {
                return @intCast(items[n]);
            } else {
                return 0;
            }
        }

        fn right_rotate(self: *Self, node: ?NodeIndex) NodeIndex {
            if (node) |n| {
                var slice = self.backing.slice();
                const left_slice = slice.items(.left_child);
                const right_slice = slice.items(.right_child);
                const height_slice = slice.items(.height);

                const left = left_slice[n].?;
                const new_left = right_slice[left];

                right_slice[left] = n;
                left_slice[n] = new_left;

                var left_height = get_height(height_slice, left_slice[n]);
                var right_height = get_height(height_slice, right_slice[n]);
                height_slice[n] = @intCast(1 + if (left_height > right_height) left_height else right_height);

                left_height = get_height(height_slice, left_slice[left]);
                right_height = get_height(height_slice, right_slice[left]);
                height_slice[left] = @intCast(1 + if (left_height > right_height) left_height else right_height);
                return left;
            }
            unreachable;
        }

        fn left_rotate(self: *Self, node: ?NodeIndex) NodeIndex {
            if (node) |n| {
                var slice = self.backing.slice();
                const left_slice = slice.items(.left_child);
                const right_slice = slice.items(.right_child);
                const height_slice = slice.items(.height);

                const x = right_slice[n].?;
                const T2 = left_slice[x];

                left_slice[x] = n;
                right_slice[n] = T2;

                var left_height = get_height(height_slice, left_slice[n]);
                var right_height = get_height(height_slice, right_slice[n]);
                height_slice[n] = @intCast(1 + if (left_height > right_height) left_height else right_height);

                left_height = get_height(height_slice, left_slice[x]);
                right_height = get_height(height_slice, right_slice[x]);
                height_slice[x] = @intCast(1 + if (left_height > right_height) left_height else right_height);
                return x;
            }
            unreachable;
        }

        fn insert_at(self: *Self, node: ?NodeIndex, item: T) !NodeIndex {
            if (node) |n| {
                var slice = self.backing.slice();

                const value = slice.items(.value)[n];

                if (item < value) {
                    const left_node = try self.insert_at(slice.items(.left_child)[n], item);
                    self.backing.items(.left_child)[n] = left_node;
                } else if (item > value) {
                    const right_node = try self.insert_at(slice.items(.right_child)[n], item);
                    self.backing.items(.right_child)[n] = right_node;
                }

                slice = self.backing.slice();
                const height_slice = slice.items(.height);
                const value_slice = slice.items(.value);
                const left_slice = slice.items(.left_child);
                const right_slice = slice.items(.right_child);

                const left_height = get_height(height_slice, left_slice[n]);
                const right_height = get_height(height_slice, right_slice[n]);
                height_slice[n] = @intCast(1 + if (left_height > right_height) left_height else right_height);

                const node_balance_factor = left_height - right_height;

                if (node_balance_factor > 1 and item < value_slice[left_slice[n].?]) {
                    return self.right_rotate(n);
                }

                if (node_balance_factor < -1 and item > value_slice[right_slice[n].?]) {
                    return self.left_rotate(n);
                }

                if (node_balance_factor > 1 and item > value_slice[left_slice[n].?]) {
                    left_slice[n] = self.left_rotate(left_slice[n]);
                    return self.right_rotate(n);
                }

                if (node_balance_factor < -1 and item < value_slice[right_slice[n].?]) {
                    right_slice[n] = self.right_rotate(right_slice[n]);
                    return self.left_rotate(n);
                }

                return n;
            } else {
                const location = self.backing.len;
                try self.backing.append(self.allocator, Node{ .value = item });
                return location;
            }
        }

        pub fn insert(self: *Self, item: T) !void {
            self.root = try self.insert_at(self.root, item);
        }

        pub fn clear(self: *Self) void {
            self.backing.shrinkRetainingCapacity(0);
            self.root = null;
        }

        fn find_at(self: Self, node: ?NodeIndex, item: T) bool {
            if (node) |n| {
                var slice = self.backing.slice();
                const value = slice.items(.value)[n];
                if (item == value) {
                    return true;
                } else if (item < value) {
                    return self.find_at(slice.items(.left_child)[n], item);
                } else {
                    return self.find_at(slice.items(.right_child)[n], item);
                }
            } else {
                return false;
            }
        }

        pub fn find(self: Self, item: T) bool {
            return self.find_at(self.root, item);
        }

        fn print_to_stderr_at(self: Self, node: ?NodeIndex, is_left: bool, height: u32) void {
            if (node) |n| {
                const curr_node = self.backing.get(n);
                std.debug.print("{s}: {d}, {d}\n", .{ if (is_left) "Left" else "Right", curr_node.value, curr_node.height });
                for (0..height - curr_node.height + 1) |_| {
                    std.debug.print("\t", .{});
                }
                self.print_to_stderr_at(curr_node.left_child, true, height);
                for (0..height - curr_node.height + 1) |_| {
                    std.debug.print("\t", .{});
                }
                self.print_to_stderr_at(curr_node.right_child, false, height);
            } else {
                std.debug.print("{s}: {s}\n", .{ if (is_left) "Left" else "Right", "NULL" });
            }
        }

        pub fn print_to_stderr(self: Self) void {
            std.debug.print("BTree: \n", .{});
            if (self.root) |r| {
                const node = self.backing.get(r);
                std.debug.print("Root: {d}, height: {}\n", .{ node.value, node.height });
                std.debug.print("\t", .{});
                self.print_to_stderr_at(node.left_child, true, node.height);
                std.debug.print("\t", .{});
                self.print_to_stderr_at(node.right_child, false, node.height);
            }
        }
    };
}

test "BTree" {
    var bt = BTree(u32).init(std.testing.allocator);
    defer bt.deinit();

    try bt.insert(79);
    try bt.insert(1);
    try bt.insert(6);
    try bt.insert(9);
    try bt.insert(88);
    try bt.insert(95);
    try bt.insert(84);
    try bt.insert(69);
    // bt.print_to_stderr();
    try bt.insert(83);
    // bt.print_to_stderr();
    // std.debug.print("Find 1: {any}\n", .{bt.find(1)});
    // std.debug.print("Find 10: {any}\n", .{bt.find(10)});
}
