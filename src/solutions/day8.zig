const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
    .part2Fn = part2,
};

const Vec3D = @Vector(3, f32);

const Circuits = std.array_list.Managed(Circuit);

const Circuit = struct {
    junction_boxes: std.array_list.Managed(JunctionBox),

    pub fn init(allocator: std.mem.Allocator) Circuit {
        return .{
            .junction_boxes = .init(allocator),
        };
    }

    pub fn deinit(self: Circuit) void {
        self.junction_boxes.deinit();
    }

    /// returns min dist to other circuit
    pub fn dist(self: Circuit, other: Circuit) f32 {
        var min_dist = std.math.floatMax(f32);
        for (self.junction_boxes.items) |a| {
            for (other.junction_boxes.items) |b| {
                const d = a.dist(b);
                if (d < min_dist)
                    min_dist = d;
            }
        }

        return min_dist;
    }

    pub fn contains(self: Circuit, other: JunctionBox) bool {
        for (self.junction_boxes.items) |item| {
            if (std.meta.eql(item, other))
                return true;
        }
        return false;
    }

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("Circuit(junction_boxes = {any})", .{self.junction_boxes.items});
    }

    pub fn lessThan(ctx: void, a: Circuit, b: Circuit) bool {
        _ = ctx;
        return a.junction_boxes.items.len < b.junction_boxes.items.len;
    }
};

const JunctionBoxes = std.array_list.Managed(JunctionBox);

const JunctionBox = struct {
    pos: Vec3D,

    fn dist(self: JunctionBox, other: JunctionBox) f32 {
        const v = self.pos - other.pos;
        var d: f32 = 0;
        for (0..3) |i| {
            d += std.math.pow(f32, v[i], 2);
        }
        return @sqrt(d);
    }

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("JunctionBox(pos={any})", .{self.pos});
    }
};

fn part1(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day8.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [512]u8 = undefined;
    var in = handle.reader(&buff);
    var boxes: JunctionBoxes = .init(allocator);

    defer {
        boxes.deinit();
    }

    while (true) {
        const line = in.interface.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };
        var it = std.mem.splitScalar(u8, line, ',');
        const pos: Vec3D = .{
            try std.fmt.parseFloat(f32, it.next().?),
            try std.fmt.parseFloat(f32, it.next().?),
            try std.fmt.parseFloat(f32, it.next().?),
        };

        std.debug.assert(it.rest().len == 0);

        const box: JunctionBox = .{ .pos = pos };
        try boxes.append(box);
    }

    var q: std.PriorityQueue([2]JunctionBox, void, compareFn) = .init(allocator, {});
    defer q.deinit();
    const sims = 1000;

    for (boxes.items) |from| {
        for (boxes.items) |to| {
            const d = from.dist(to);
            if (d == 0) continue;
            try q.add([_]JunctionBox{ from, to });
        }
    }

    var circuits: Circuits = .init(allocator);
    defer {
        for (circuits.items) |c| c.deinit();
        circuits.deinit();
    }

    var curr_sims: usize = 0;
    const Result = union(enum) {
        new,
        ignore,
        insert: struct { usize, JunctionBox },
        merge: struct { usize, usize },
    };
    while (curr_sims < sims) {
        const from, const to = q.remove();
        _ = q.remove();

        var result: Result = .new;
        r: for (0.., circuits.items) |i, c| {
            if (c.contains(from)) {
                // in itself; ignore
                if (c.contains(to)) {
                    result = .ignore;
                    break :r;
                }

                for (0.., circuits.items) |j, c2| {
                    if (i == j)
                        continue;
                    if (c2.contains(to)) {
                        result = .{ .merge = .{ i, j } };
                        break :r;
                    }
                }

                result = .{ .insert = .{ i, to } };
            } else if (c.contains(to)) {
                for (0.., circuits.items) |j, c2| {
                    if (i == j)
                        continue;
                    if (c2.contains(from)) {
                        result = .{ .merge = .{ i, j } };
                        break :r;
                    }
                }

                result = .{ .insert = .{ i, from } };
            }
        }

        switch (result) {
            .ignore => {},
            .new => {
                var c: Circuit = .init(allocator);
                try c.junction_boxes.append(from);
                try c.junction_boxes.append(to);
                try circuits.append(c);
            },
            .insert => |insert| {
                const idx, const box = insert;

                try circuits.items[idx].junction_boxes.append(box);
            },
            .merge => |idxs| {
                const i, const j = idxs;
                const removed = circuits.swapRemove(j);
                try circuits.items[i].junction_boxes.appendSlice(removed.junction_boxes.items);
                removed.deinit();
            },
        }
        curr_sims += 1;
    }

    var sum: usize = 1;
    std.mem.sort(Circuit, circuits.items, {}, Circuit.lessThan);

    for (0..3) |idx| {
        const circuit = circuits.items[circuits.items.len - (idx + 1)];

        sum *= circuit.junction_boxes.items.len;
    }

    std.log.info("{d}", .{sum});
}

fn part2(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day8.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [512]u8 = undefined;
    var in = handle.reader(&buff);
    var boxes: JunctionBoxes = .init(allocator);

    defer {
        boxes.deinit();
    }

    while (true) {
        const line = in.interface.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };
        var it = std.mem.splitScalar(u8, line, ',');
        const pos: Vec3D = .{
            try std.fmt.parseFloat(f32, it.next().?),
            try std.fmt.parseFloat(f32, it.next().?),
            try std.fmt.parseFloat(f32, it.next().?),
        };

        std.debug.assert(it.rest().len == 0);

        const box: JunctionBox = .{ .pos = pos };
        try boxes.append(box);
    }

    var q: std.PriorityQueue([2]JunctionBox, void, compareFn) = .init(allocator, {});
    defer q.deinit();

    for (boxes.items) |from| {
        for (boxes.items) |to| {
            const d = from.dist(to);
            if (d == 0) continue;
            try q.add([_]JunctionBox{ from, to });
        }
    }

    var circuits: Circuits = .init(allocator);
    defer {
        for (circuits.items) |c| c.deinit();
        circuits.deinit();
    }

    var curr_sims: usize = 0;
    const Result = union(enum) {
        new,
        ignore,
        insert: struct { usize, JunctionBox },
        merge: struct { usize, usize },
    };

    var last: [2]JunctionBox = undefined;
    while (q.peek() != null) {
        const from, const to = q.remove();

        _ = q.remove();

        var result: Result = .new;
        r: for (0.., circuits.items) |i, c| {
            if (c.contains(from)) {
                // in itself; ignore
                if (c.contains(to)) {
                    result = .ignore;
                    break :r;
                }

                for (0.., circuits.items) |j, c2| {
                    if (i == j)
                        continue;
                    if (c2.contains(to)) {
                        result = .{ .merge = .{ i, j } };
                        break :r;
                    }
                }

                result = .{ .insert = .{ i, to } };
            } else if (c.contains(to)) {
                for (0.., circuits.items) |j, c2| {
                    if (i == j)
                        continue;
                    if (c2.contains(from)) {
                        result = .{ .merge = .{ i, j } };
                        break :r;
                    }
                }

                result = .{ .insert = .{ i, from } };
            }
        }

        if (result != .ignore) {
            last[0] = from;
            last[1] = to;
        }

        switch (result) {
            .ignore => {},
            .new => {
                var c: Circuit = .init(allocator);
                try c.junction_boxes.append(from);
                try c.junction_boxes.append(to);
                try circuits.append(c);
            },
            .insert => |insert| {
                const idx, const box = insert;

                try circuits.items[idx].junction_boxes.append(box);
            },
            .merge => |idxs| {
                const i, const j = idxs;
                const removed = circuits.swapRemove(j);
                try circuits.items[i].junction_boxes.appendSlice(removed.junction_boxes.items);
                removed.deinit();
            },
        }
        curr_sims += 1;
    }

    // 170084350
    const sum = last[0].pos[0] * last[1].pos[0];

    std.log.info("{d}", .{sum});
}

fn compareFn(_: void, a: [2]JunctionBox, b: [2]JunctionBox) std.math.Order {
    const a_dist = a[0].dist(a[1]);
    const b_dist = b[0].dist(b[1]);

    return std.math.order(a_dist, b_dist);
}
