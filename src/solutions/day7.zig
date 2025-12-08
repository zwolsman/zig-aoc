const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
    .part2Fn = part2,
};

fn part1(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day7.txt", .{ .mode = .read_only });
    defer handle.close();

    var in = handle.reader(&.{});
    const txt = try in.interface.allocRemaining(allocator, .unlimited);
    defer allocator.free(txt);

    var grid = try Grid.init(allocator, txt);
    defer grid.deinit();

    std.log.debug("{d} {d}", .{ grid.y, grid.max_y });

    while (grid.y < grid.max_y) {
        try grid.tick();
    }

    std.log.info("{d}", .{grid.hit_splitters.count()});
}

fn part2(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day7.txt", .{ .mode = .read_only });
    defer handle.close();

    var in = handle.reader(&.{});
    const txt = try in.interface.allocRemaining(allocator, .unlimited);
    defer allocator.free(txt);

    var grid = try Grid.init(allocator, txt);
    defer grid.deinit();

    while (grid.y < grid.max_y) {
        try grid.tick();
    }

    var sum: usize = 0;
    var it = grid.beams.iterator();
    while (it.next()) |entry| {
        if (entry.key_ptr.*.y != grid.max_y)
            continue;
        sum += entry.value_ptr.*;
    }

    // printGrid(&grid);

    std.log.info("{d}", .{sum});
}

fn printGrid(grid: *const Grid) void {
    for (0..grid.max_y) |y| {
        for (0..grid.max_y) |x| {
            const coord: Coordinate = .{ .x = x, .y = y };
            if (grid.beams.get(coord)) |n| {
                std.debug.print("{d:3}", .{n});
            } else {
                var is_splitter = false;
                for (grid.splitters.items) |splitter| {
                    if (std.meta.eql(splitter, coord)) {
                        is_splitter = true;
                        std.debug.print("  -", .{});
                    }
                }
                if (!is_splitter)
                    std.debug.print("{d:3}", .{0});
            }
        }
        std.debug.print("\n", .{});
    }
}

const Direction = enum {
    const Self = @This();
    left,
    right,
    up,
    down,

    pub fn vector(self: Self) struct { isize, isize } {
        return switch (self) {
            .left => .{ -1, 0 },
            .right => .{ 1, 0 },
            .up => .{ 0, -1 },
            .down => .{ 0, 1 },
        };
    }

    pub fn plus(self: Direction, other: Direction) struct { isize, isize } {
        const a = self.vector();
        const b = other.vector();

        return .{ a.@"0" + b.@"0", a.@"1" + b.@"1" };
    }
};

const Coordinate = struct {
    x: usize,
    y: usize,

    fn plus(self: *const Coordinate, dir: Direction) Coordinate {
        const vx, const vy = dir.vector();

        return .{
            .x = @as(usize, @intCast(@as(isize, @intCast(self.x)) + vx)),
            .y = @as(usize, @intCast(@as(isize, @intCast(self.y)) + vy)),
        };
    }
};

const Grid = struct {
    const BEAM_DIR = Direction.down;
    const Beams = std.AutoHashMap(Coordinate, usize);

    beams: Beams,
    splitters: std.array_list.Managed(Coordinate),
    hit_splitters: std.AutoHashMap(Coordinate, void),
    max_y: usize,
    y: usize = 0,

    pub fn init(allocator: std.mem.Allocator, raw_grid: []u8) !Grid {
        var line_it = std.mem.tokenizeScalar(u8, raw_grid, '\n');
        var y: usize = 0;
        var grid: Grid = undefined;

        grid.beams = .init(allocator);
        grid.splitters = .init(allocator);
        grid.hit_splitters = .init(allocator);

        while (line_it.next()) |line| {
            for (0.., line) |x, c| {
                switch (c) {
                    'S' => {
                        try grid.beams.putNoClobber(.{ .x = x, .y = y }, 1);
                    },
                    '^' => {
                        try grid.splitters.append(.{ .x = x, .y = y });
                    },
                    '.' => {},
                    else => unreachable,
                }

                if (c == 'S') {}
            }
            y += 1;
        }

        grid.max_y = y;
        grid.y = 0;

        return grid;
    }

    pub fn tick(self: *Grid) !void {
        var clone = try self.beams.clone();
        defer clone.deinit();
        var it = clone.iterator();
        while (it.next()) |entry| beam: {
            if (entry.key_ptr.*.y != self.y)
                continue;

            const next_beam_pos = entry.key_ptr.plus(BEAM_DIR);
            if (next_beam_pos.y > self.max_y) {
                continue;
            }

            for (self.splitters.items) |splitter| {
                // have to split!
                if (std.meta.eql(next_beam_pos, splitter)) {
                    for (split(splitter)) |s| {
                        try self.hit_splitters.put(splitter, {});

                        const e = try self.beams.getOrPut(s);
                        if (e.found_existing) {
                            e.value_ptr.* = e.value_ptr.* + entry.value_ptr.*;
                        } else {
                            e.value_ptr.* = entry.value_ptr.*;
                        }
                    }

                    break :beam;
                }
            }

            const result = try self.beams.getOrPut(next_beam_pos);
            if (result.found_existing) {
                result.value_ptr.* = result.value_ptr.* + entry.value_ptr.*;
            } else {
                result.value_ptr.* = entry.value_ptr.*;
            }
        }

        self.y += 1;
    }

    fn split(splitter: Coordinate) [2]Coordinate {
        return [2]Coordinate{
            splitter.plus(Direction.left),
            splitter.plus(Direction.right),
        };
    }

    pub fn deinit(self: *Grid) void {
        self.beams.deinit();
        self.splitters.deinit();
        self.hit_splitters.deinit();
    }
};
