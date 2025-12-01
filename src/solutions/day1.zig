const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
    .part2Fn = part2,
};

fn part1(allocator: std.mem.Allocator) !void {
    _ = allocator;
    var handle = try std.fs.cwd().openFileZ("./inputs/day1.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [128]u8 = undefined;
    var in = handle.reader(&buff);

    var dial: isize = 50;
    var result: usize = 0;
    while (true) {
        const line = in.interface.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };

        const sign: isize = if (line[0] == 'R') -1 else 1;
        const ticks = try std.fmt.parseInt(u16, line[1..], 10);

        dial = @mod(dial + (ticks * sign), 100);

        if (dial == 0)
            result += 1;
    }

    std.log.debug("{d}", .{result});
}

fn part2(allocator: std.mem.Allocator) !void {
    _ = allocator;
    var handle = try std.fs.cwd().openFileZ("./inputs/day1.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [128]u8 = undefined;
    var in = handle.reader(&buff);

    var dial: isize = 50;
    var result: usize = 0;
    while (true) {
        const line = in.interface.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };

        const sign: isize = if (line[0] == 'R') 1 else -1;
        const distance = try std.fmt.parseInt(u16, line[1..], 10);

        const n = @abs(@divExact(distance - @rem(distance, 100), 100));
        result += n;

        const rem_dist = sign * @rem(distance, 100);

        if (dial + rem_dist > 100)
            result += 1;

        if (dial + rem_dist < 0 and dial != 0)
            result += 1;

        dial = @mod(dial + rem_dist, 100);

        if (dial == 0)
            result += 1;
    }

    std.log.debug("{d}", .{result});
}
