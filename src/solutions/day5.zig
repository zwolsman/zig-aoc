const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
    .part2Fn = part2,
};

const Range = struct {
    start: usize,
    end: usize,

    fn size(range: *const Range) usize {
        return range.end - range.start + 1;
    }

    fn contains(self: *const Range, point: usize) bool {
        return self.start <= point and self.end >= point;
    }

    fn intersects(self: *const Range, other: *const Range) ?enum { full, partial } {
        if (self.contains(other.start)) {
            if (self.contains(other.end))
                return .full
            else
                return .partial;
        }
        if (other.contains(self.start) or other.contains(self.end)) {
            return .partial;
        }
        return null;
    }
};

fn part1(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day5.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [128]u8 = undefined;
    var in = handle.reader(&buff);

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

fn part2(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day5.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [128]u8 = undefined;
    var in = handle.reader(&buff);

    var ranges: std.array_list.Managed(Range) = .init(allocator);
    defer ranges.deinit();

    while (true) {
        const line = in.interface.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };
        if (line.len == 0)
            break;

        var split = std.mem.splitScalar(u8, line, '-');
        try ranges.append(.{
            .start = try std.fmt.parseInt(usize, split.next().?, 10),
            .end = try std.fmt.parseInt(usize, split.next().?, 10),
        });
    }

    while (true) {
        std.mem.sort(Range, ranges.items, {}, inner);

        var had_intersects = false;
        for (0.., ranges.items) |i, *r| {
            std.debug.assert(r.end >= r.start);
            var j: usize = i + 1;
            while (j < ranges.items.len) {
                const r2 = ranges.items[j];
                const intersects = r.intersects(&r2) orelse {
                    j += 1;
                    continue;
                };
                had_intersects = true;
                switch (intersects) {
                    .full => {
                        _ = ranges.orderedRemove(j);
                        continue;
                    },
                    .partial => {
                        if (r.end == r2.start) {
                            const removed = ranges.orderedRemove(j);
                            r.end = removed.end;

                            continue;
                        } else if (r.contains(r2.start) and r2.contains(r.end)) {
                            r.end = r2.end;
                            _ = ranges.orderedRemove(j);

                            continue;
                        } else {
                            std.debug.assert(false);
                        }
                    },
                }
                j += 1;
            }
        }
        if (!had_intersects)
            break;
    }

    var fresh_ingredients: usize = 0;
    for (ranges.items) |r| {
        fresh_ingredients += r.size();
    }

    std.log.info("{d}", .{fresh_ingredients});
}

pub fn inner(_: void, a: Range, b: Range) bool {
    if (a.start == b.start)
        return a.end < b.end;
    return a.start < b.start;
}
