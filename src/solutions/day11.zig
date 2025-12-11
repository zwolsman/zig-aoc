const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
    .part2Fn = part2,
};

fn part1(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day11.txt", .{ .mode = .read_only });
    defer handle.close();

    var in = handle.reader(&.{});
    const txt = try in.interface.allocRemaining(allocator, .unlimited);
    defer allocator.free(txt);

    var tree = TreeMap.init(allocator);
    defer {
        var it = tree.valueIterator();
        while (it.next()) |n| n.deinit();
        tree.deinit();
    }
    try tree.ensureTotalCapacity(1024);
    var line_reader = std.Io.Reader.fixed(txt);

    while (true) {
        const line = line_reader.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };

        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const src = it.next().?;

        const result = try tree.getOrPut(src[0 .. src.len - 1]);
        if (!result.found_existing) {
            result.value_ptr.* = .init(allocator);
        }

        var node = result.value_ptr;
        while (it.next()) |dst| try node.append(dst);
    }

    const paths = try walkNodeWithCache(allocator, tree, "you", "out");

    std.log.info("{d}", .{paths});
}

fn part2(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day11.txt", .{ .mode = .read_only });
    defer handle.close();

    var in = handle.reader(&.{});
    const txt = try in.interface.allocRemaining(allocator, .unlimited);
    defer allocator.free(txt);

    var tree = TreeMap.init(allocator);
    defer {
        var it = tree.valueIterator();
        while (it.next()) |n| n.deinit();
        tree.deinit();
    }

    try tree.ensureTotalCapacity(1024);
    var line_reader = std.Io.Reader.fixed(txt);

    while (true) {
        const line = line_reader.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };

        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const src = it.next().?;

        const result = try tree.getOrPut(src[0 .. src.len - 1]);
        if (!result.found_existing) {
            result.value_ptr.* = .init(allocator);
        }

        var node = result.value_ptr;
        while (it.next()) |dst| try node.append(dst);
    }

    var paths: usize = 0;

    // svr -> fft -> dac -> out
    paths += try walkNodeWithCache(allocator, tree, "svr", "fft") *
        try walkNodeWithCache(allocator, tree, "fft", "dac") *
        try walkNodeWithCache(allocator, tree, "dac", "out");

    // svr -> dac -> fft -> out
    paths += try walkNodeWithCache(allocator, tree, "svr", "dac") *
        try walkNodeWithCache(allocator, tree, "dac", "fft") *
        try walkNodeWithCache(allocator, tree, "fft", "out");

    std.log.info("{d}", .{paths});
}

const TreeMap = std.StringHashMap(std.array_list.Managed([]const u8));

fn walkNodeWithCache(allocator: std.mem.Allocator, map: TreeMap, start: []const u8, end: []const u8) !usize {
    const Walker = struct {
        const Self = @This();
        const Cache = std.StringHashMap(usize);
        cache: Cache,
        fn init(a: std.mem.Allocator, expected_count: u32) !Self {
            var c: Cache = .init(a);
            try c.ensureTotalCapacity(expected_count);

            return .{
                .cache = c,
            };
        }

        fn deinit(self: *Self) void {
            self.cache.deinit();
        }

        fn walk(self: *Self, tree: TreeMap, curr: []const u8, target: []const u8) !usize {
            if (std.mem.eql(u8, curr, target)) return 1;
            if (std.mem.eql(u8, curr, "out")) return 0;

            const result = try self.cache.getOrPut(curr);

            if (!result.found_existing) {
                var sum: usize = 0;

                for (tree.get(curr).?.items) |n| {
                    sum += try self.walk(tree, n, target);
                }
                result.value_ptr.* = sum;
            }

            return result.value_ptr.*;
        }
    };

    var w = try Walker.init(allocator, map.count());
    defer w.deinit();

    return try w.walk(map, start, end);
}
