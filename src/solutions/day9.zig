const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
};

const Vec2D = @Vector(2, f64);

fn part1(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day9.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [128]u8 = undefined;
    var in = handle.reader(&buff);
    var points: std.array_list.Managed(Vec2D) = .init(allocator);
    defer points.deinit();

    while (true) {
        const line = in.interface.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };
        var it = std.mem.splitScalar(u8, line, ',');
        const pos: Vec2D = .{
            try std.fmt.parseFloat(f32, it.next().?),
            try std.fmt.parseFloat(f32, it.next().?),
        };
        std.debug.assert(it.rest().len == 0);
        try points.append(pos);
    }

    var q: std.PriorityQueue([2]Vec2D, void, compare) = .init(allocator, {});
    defer q.deinit();

    for (0.., points.items) |i, p1| {
        for (0.., points.items) |j, p2| {
            if (i == j)
                continue;
            try q.add([_]Vec2D{ p1, p2 });
        }
    }
    std.log.debug("{d}", .{q.count()});
    const largest = q.remove();

    std.log.info("{d}", .{area(largest)});
}

fn compare(ctx: void, a: [2]Vec2D, b: [2]Vec2D) std.math.Order {
    _ = ctx;

    return std.math.order(area(b), area(a));
}

fn area(points: [2]Vec2D) f64 {
    const y1 = @min(points[0][1], points[1][1]);
    const y2 = @max(points[0][1], points[1][1]);

    const x1 = @min(points[0][0], points[1][0]);
    const x2 = @max(points[0][0], points[1][0]);

    const length = @abs(y1 - y2) + 1;
    const width = @abs(x1 - x2) + 1;

    return length * width;
}
