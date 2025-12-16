const std = @import("std");
const builtin = @import("builtin");

const flags = @import("flags");

pub const default_level: std.log.Level = switch (builtin.mode) {
    .Debug => .debug,
    .ReleaseSafe => .notice,
    .ReleaseFast => .info,
    .ReleaseSmall => .err,
};

pub const Solution = struct {
    part1Fn: ?*const fn (std.mem.Allocator) anyerror!void = null,
    part2Fn: ?*const fn (std.mem.Allocator) anyerror!void = null,

    fn part1(self: *const Solution, allocator: std.mem.Allocator) !void {
        if (self.part1Fn) |callback| {
            std.log.info("Running part 1", .{});
            try callback(allocator);
        } else {
            std.log.info("Skipping part 2", .{});
        }
    }

    fn part2(self: *const Solution, allocator: std.mem.Allocator) !void {
        if (self.part2Fn) |callback| {
            std.log.info("Running part 2", .{});
            try callback(allocator);
        } else {
            std.log.info("Skipping part 2", .{});
        }
    }

    fn run(self: *const Solution, allocator: std.mem.Allocator) void {
        var timer = std.time.Timer.start() catch unreachable;
        self.part1(allocator) catch |err| {
            std.log.warn("Failed to run part 1: {}", .{err});
        };

        const p1_duration = timer.lap();
        std.log.info("part 1 took {D}", .{p1_duration});

        timer.reset();
        self.part2(allocator) catch |err| {
            std.log.warn("Failed to run part 2: {}", .{err});
        };

        const p2_duration = timer.lap();
        std.log.info("part 2 took {D}", .{p2_duration});
    }
};

// TOOD: can I make this comptime?
const solutions = [_]Solution{
    @import("solutions/day1.zig").solution,
    @import("solutions/day2.zig").solution,
    @import("solutions/day3.zig").solution,
    @import("solutions/day4.zig").solution,
    @import("solutions/day5.zig").solution,
    @import("solutions/day6.zig").solution,
    @import("solutions/day7.zig").solution,
    @import("solutions/day8.zig").solution,
    @import("solutions/day9.zig").solution,
    @import("solutions/day10.zig").solution,
    @import("solutions/day11.zig").solution,
    @import("solutions/day12.zig").solution,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const raw_args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, raw_args);
    const args = flags.parse(raw_args, "aoc", struct {
        day: ?u8,
        pub const switches = .{
            .day = 'd',
        };
    }, .{});

    if (args.day) |day| {
        if (day < 1 or day > solutions.len) return error.InvalidDay;

        std.log.info("Running day {d}", .{day});
        solutions[day - 1].run(allocator);
    } else {
        for (0.., solutions) |day, s| {
            std.log.info("Running day {d}", .{day + 1});
            s.run(allocator);
        }
    }
}
