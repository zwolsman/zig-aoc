const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
};

fn part1(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day1.txt", .{ .mode = .read_only });
    defer handle.close();

    var in = handle.reader(&.{});
    const data = try in.interface.readAlloc(allocator, try in.getSize());
    defer allocator.free(data);

    std.log.debug("read: {s}", .{data});
}
