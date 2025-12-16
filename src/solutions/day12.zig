const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
};

fn part1(allocator: std.mem.Allocator) !void {
    _ = allocator;
    var handle = try std.fs.cwd().openFileZ("./inputs/day12.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [128]u8 = undefined;
    var in = handle.reader(&buff);

    var shapes: [6]usize = undefined;

    for (0..shapes.len) |i| {
        const id = try in.interface.takeDelimiterExclusive('\n');
        std.debug.assert(std.mem.eql(u8, id, &[_]u8{ @as(u8, @intCast(i)) + '0', ':' }));
        var size: usize = 0;
        for (0..3) |_| {
            const line = try in.interface.takeDelimiterExclusive('\n');
            for (line) |c| {
                if (c == '#')
                    size += 1;
            }
        }

        shapes[i] = size;

        std.debug.assert((try in.interface.takeDelimiterExclusive('\n')).len == 0);
    }

    var fits: usize = 0;
    while (true) {
        const line = in.interface.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };

        var it = std.mem.tokenizeScalar(u8, line, ' ');

        const size = it.next().?;
        const split_i = std.mem.indexOfScalar(u8, size, 'x').?;
        const w = try std.fmt.parseInt(usize, size[0..split_i], 10);
        const l = try std.fmt.parseInt(usize, size[split_i + 1 .. size.len - 1], 10);

        var shape_idx: usize = 0;
        var sum: usize = 0;
        while (it.next()) |raw_n| {
            const req = try std.fmt.parseInt(usize, raw_n, 10);
            sum += shapes[shape_idx] * req;
            shape_idx += 1;
        }

        if (sum <= w * l)
            fits += 1;
    }

    std.log.debug("{d}", .{fits});
}
