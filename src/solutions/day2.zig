const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
    .part2Fn = part2,
};

fn part1(allocator: std.mem.Allocator) !void {
    _ = allocator;
    var handle = try std.fs.cwd().openFileZ("./inputs/day2.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [128]u8 = undefined;
    var in = handle.reader(&buff);

    var sum: usize = 0;
    while (true) {
        const range = in.interface.takeDelimiterExclusive(',') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };

        var it = std.mem.splitScalar(u8, range, '-');
        const start = try std.fmt.parseInt(u64, it.next().?, 10);
        const end = try std.fmt.parseInt(u64, it.next().?, 10);
        std.debug.assert(it.next() == null);

        for (start..end + 1) |product_id| {
            if (!isValid(product_id)) {
                sum += product_id;
            }
        }
    }
    std.log.debug("{d}", .{sum});
}

fn isValid(n: u64) bool {
    var buff: [64]u8 = undefined;
    const str = std.fmt.bufPrint(&buff, "{d}", .{n}) catch unreachable;

    const left = str[0 .. str.len / 2];
    const right = str[str.len / 2 ..];

    return !std.mem.eql(u8, left, right);
}

fn part2(allocator: std.mem.Allocator) !void {
    _ = allocator;
}
