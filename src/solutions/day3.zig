const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
    .part2Fn = part2,
};

fn part1(allocator: std.mem.Allocator) !void {
    _ = allocator;
    var handle = try std.fs.cwd().openFileZ("./inputs/day3.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [128]u8 = undefined;
    var in = handle.reader(&buff);

    var output_joltage: usize = 0;
    while (true) {
        const bank = in.interface.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };

        var max_joltage: usize = 0;
        for (0.., bank[0 .. bank.len - 1]) |i, battery_1| {
            for (bank[i + 1 .. bank.len]) |battery_2| {
                const joltage = (battery_1 - '0') * 10 + (battery_2 - '0');
                if (joltage > max_joltage) {
                    max_joltage = joltage;
                }
            }
        }

        output_joltage += max_joltage;
    }
    std.log.info("{d}", .{output_joltage});
}

fn part2(allocator: std.mem.Allocator) !void {
    _ = allocator;
}
