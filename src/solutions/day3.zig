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

        var battery_buff: [2]u8 = undefined;
        solve(&battery_buff, bank);

        var max_joltage: usize = 0;
        for (0.., battery_buff) |i, battery| {
            max_joltage += (battery - '0') * std.math.pow(usize, 10, battery_buff.len - i - 1);
        }
        output_joltage += max_joltage;
    }
    std.log.info("{d}", .{output_joltage});
}

fn part2(allocator: std.mem.Allocator) !void {
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

        var battery_buff: [12]u8 = undefined;
        solve(&battery_buff, bank);

        var max_joltage: usize = 0;
        for (0.., battery_buff) |i, battery| {
            max_joltage += (battery - '0') * std.math.pow(usize, 10, battery_buff.len - i - 1);
        }
        output_joltage += max_joltage;
    }

    std.log.info("{d}", .{output_joltage});
}

fn solve(buff: []u8, bank: []const u8) void {
    var left: usize = 0;
    for (0..buff.len) |i| {
        const space = bank[left .. bank.len - (buff.len - i - 1)];

        var max: u8 = 0;
        var max_index: usize = 0;
        for (0.., space) |j, battery| {
            if (battery > max) {
                max = battery;
                max_index = j;
            }
            if (battery == '9')
                break;
        }

        left += max_index + 1;

        buff[i] = max;
    }
}
