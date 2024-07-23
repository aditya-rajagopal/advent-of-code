const std = @import("std");
const assert = @import("assert.zig").assert;

pub fn RingQueueStatic(T: type, comptime length: u32) type {
    const type_info = @typeInfo(T);
    switch (type_info) {
        .Int, .Float => {},
        .Struct => if (!@hasDecl(T, "add")) {
            @compileError("Provided struct to RingQueueStatic does not have an add method");
        },
        else => @compileError("RingQueueStatic does not supprt provided type"),
    }
    return struct {
        items: [length]T = undefined,
        head: u32 = 0,
        len: u32 = 0,

        const Self = @This();

        pub fn enqueue(self: *Self, item: T) u32 {
            assert(self.len != length, "Ring queue full ", .{});

            const tail = @mod(self.head + self.len, length);
            self.len += 1;
            self.items[tail] = item;
            return tail;
        }

        pub fn enqueue_many(self: *Self, count: u32, item: T) u32 {
            assert(
                count <= length,
                "Insufficient capacity in RingQueue: have {}, requestd {}",
                .{ length, count },
            );
            assert(
                self.len <= length - count,
                "Not enough space in Ringqueue: requested {} have {}",
                .{ count, length - self.len },
            );

            const tail = @mod(self.head + self.len, length);
            self.len += count;
            var post_tail: u32 = 0;
            if (tail + count < length) {
                post_tail = tail + count;
                @memset(self.items[tail..post_tail], item);
            } else {
                post_tail = @mod(tail + count, length);
                @memset(self.items[tail..], item);
                @memset(self.items[0..post_tail], item);
            }
            return post_tail;
        }

        pub fn increment_values(self: *Self, count: u32, value: T) void {
            assert(
                self.len >= count,
                "Not enough elements in the queue to increment: expected {}, got {}",
                .{ count, self.len },
            );

            var i: u32 = 0;
            while (i < count) : (i += 1) {
                const pos = @mod(self.head + i, length);
                switch (type_info) {
                    .Int, .Float => self.items[pos] += value,
                    .Struct => self.items[pos].add(value),
                    else => unreachable,
                }
            }
        }

        pub fn dequeue(self: *Self) T {
            assert(self.len != 0, "Ring queue empty", .{});

            const value = self.items[self.head];
            self.head = @mod(self.head + 1, length);
            self.len -= 1;
            return value;
        }
    };
}

pub fn RingQueue(T: type) type {
    const type_info = @typeInfo(T);
    switch (type_info) {
        .Int, .Float => {},
        else => @compileError("RingQueueStatic does not supprt provided type"),
    }
    return struct {
        items: []T,
        head: u32 = 0,
        len: u32 = 0,
        capacity: u32 = 0,
        allocator: std.mem.Allocator,

        const Self = @This();

        const default_capacity = 8;

        pub fn init(allocator: std.mem.Allocator) !Self {
            return .{
                .items = try allocator.alloc(T, default_capacity),
                .capacity = default_capacity,
                .allocator = allocator,
            };
        }

        pub fn initCapacity(allocator: std.mem.Allocator, capacity: u32) !Self {
            return .{
                .items = try allocator.alloc(T, capacity),
                .capacity = capacity,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        pub fn enqueue(self: *Self, item: T) u32 {
            assert(self.len != self.capacity, "Ring queue full ", .{});

            const tail = @mod(self.head + self.len, self.capacity);
            self.len += 1;
            self.items[tail] = item;
            return tail;
        }

        pub fn enqueue_many(self: *Self, count: u32, item: T) u32 {
            assert(
                self.len <= self.capacity - count,
                "Not enough space in Ringqueue: requested {} have {}",
                .{ count, self.capacity - self.len },
            );

            const tail = @mod(self.head + self.len, self.capacity);
            self.len += count;
            var post_tail: u32 = 0;
            if (tail + count < self.capacity) {
                post_tail = tail + count;
                @memset(self.items[tail..post_tail], item);
            } else {
                post_tail = @mod(tail + count, self.capacity);
                @memset(self.items[tail..], item);
                @memset(self.items[0..post_tail], item);
            }
            return post_tail;
        }

        pub fn increment_values(self: *Self, count: u32, value: T) void {
            assert(
                self.len >= count,
                "Not enough elements in the queue to increment: expected {}, got {}",
                .{ count, self.len },
            );

            var i: u32 = 0;
            while (i < count) : (i += 1) {
                const pos = @mod(self.head + i, self.capacity);
                switch (type_info) {
                    .Int, .Float => self.items[pos] += value,
                    else => unreachable,
                }
            }
        }

        pub fn dequeue(self: *Self) T {
            assert(self.len != 0, "Ring queue empty", .{});

            const value = self.items[self.head];
            self.head = @mod(self.head + 1, self.capacity);
            self.len -= 1;
            return value;
        }
    };
}

test "Ring queue" {
    var rqueue = RingQueueStatic(u8, 3){};
    _ = rqueue.enqueue(0);
    _ = rqueue.enqueue(1);
    _ = rqueue.enqueue(2);
    try std.testing.expectEqual(0, rqueue.dequeue());
    try std.testing.expectEqual(1, rqueue.dequeue());
    try std.testing.expectEqual(2, rqueue.dequeue());
    _ = rqueue.enqueue(0);
    _ = rqueue.dequeue();
    _ = rqueue.enqueue_many(3, 10);
    rqueue.increment_values(3, 1);
    rqueue.increment_values(3, 10);
    try std.testing.expectEqual(21, rqueue.dequeue());
    try std.testing.expectEqual(21, rqueue.dequeue());
    try std.testing.expectEqual(21, rqueue.dequeue());

    var rqueue_h = try RingQueue(u8).init(std.testing.allocator);
    defer rqueue_h.deinit();
    _ = rqueue_h.enqueue(0);
    _ = rqueue_h.enqueue(1);
    _ = rqueue_h.enqueue(2);
    try std.testing.expectEqual(0, rqueue_h.dequeue());
    try std.testing.expectEqual(1, rqueue_h.dequeue());
    try std.testing.expectEqual(2, rqueue_h.dequeue());
}
