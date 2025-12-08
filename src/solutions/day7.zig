const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
};

fn part1(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day7.txt", .{ .mode = .read_only });
    defer handle.close();

    var in = handle.reader(&.{});
    const txt = try in.interface.allocRemaining(allocator, .unlimited);
    defer allocator.free(txt);

    var grid = try Grid.init(allocator, txt);
    defer grid.deinit();

    while (try grid.tick()) {}
    std.log.info("{d}", .{grid.hit_splitters.count()});
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

    beams: std.AutoHashMap(Coordinate, bool),
    splitters: std.array_list.Managed(Coordinate),
    hit_splitters: std.AutoHashMap(Coordinate, void),
    max_y: usize,

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
                        try grid.beams.putNoClobber(.{ .x = x, .y = y }, true);
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

        return grid;
    }

    pub fn tick(self: *Grid) !bool {
        var did_tick = false;

        var clone = try self.beams.clone();
        defer clone.deinit();
        var it = clone.iterator();
        while (it.next()) |entry| beam: {
            if (!entry.value_ptr.*)
                continue;
            try self.beams.put(entry.key_ptr.*, false);

            did_tick = true;
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
                        if (e.found_existing) continue;

                        e.value_ptr.* = true;
                    }

                    break :beam;
                }
            }

            try self.beams.put(next_beam_pos, true);
        }

        return did_tick;
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
