const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
};

fn part1(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day5.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [128]u8 = undefined;
    var in = handle.reader(&buff);

    const Range = struct {
        start: usize,
        end: usize,
    };

    var ranges: std.array_list.Managed(Range) = .init(allocator);
    defer ranges.deinit();

    var fresh_ingredients: usize = 0;
    while (true) next_line: {
        const line = in.interface.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };
        if (line.len == 0)
            continue;

        if (std.mem.containsAtLeastScalar(u8, line, 1, '-')) {
            var split = std.mem.splitScalar(u8, line, '-');
            try ranges.append(.{
                .start = try std.fmt.parseInt(usize, split.next().?, 10),
                .end = try std.fmt.parseInt(usize, split.next().?, 10),
            });
        } else {
            const ingredient_id = try std.fmt.parseInt(usize, line, 10);

            for (ranges.items) |range| {
                if (ingredient_id >= range.start and ingredient_id <= range.end) {
                    fresh_ingredients += 1;
                    break :next_line;
                }
            }
        }
    }
    std.log.info("{d}", .{fresh_ingredients});
}
