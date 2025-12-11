const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
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
        std.log.debug("src: {s}", .{src[0 .. src.len - 1]});
        const result = try tree.getOrPut(src[0 .. src.len - 1]);
        if (!result.found_existing) {
            result.value_ptr.* = .init(allocator);
        }

        var node = result.value_ptr;
        while (it.next()) |dst| try node.append(dst);
    }
    std.log.debug("build tree, size={d}", .{tree.count()});
    var k_it = tree.keyIterator();
    while (k_it.next()) |k| std.log.debug("{s}", .{k.*});

    var paths: usize = 0;
    for (tree.get("you").?.items) |n| {
        paths += walkNode(tree, n);
    }

    std.log.info("{d}", .{paths});
}

const TreeMap = std.StringHashMap(std.array_list.Managed([]const u8));

fn walkNode(tree: TreeMap, curr: []const u8) usize {
    if (std.mem.eql(u8, curr, "out"))
        return 1;
    const node = tree.get(curr) orelse unreachable;

    var sum: usize = 0;
    for (node.items) |n| {
        sum += walkNode(tree, n);
    }

    return sum;
}
