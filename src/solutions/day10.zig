const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
};

fn part1(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day10.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [512]u8 = undefined;
    var in = handle.reader(&buff);

    var total_runs: usize = 0;
    while (true) {
        const line = in.interface.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };

        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const raw_target = it.next().?;
        var target: usize = 0;
        for (0.., raw_target[1 .. raw_target.len - 1]) |offset, l| {
            const pos: u6 = @intCast(offset);

            switch (l) {
                '.' => {},
                '#' => target |= @as(usize, 1) << pos,
                else => unreachable,
            }
        }

        var buttons: std.array_list.Managed(usize) = .init(allocator);
        defer buttons.deinit();
        var timer = std.time.Timer.start() catch unreachable;
        while (it.peek()) |raw_btn| {
            if (raw_btn[0] != '(') {
                break;
            }
            _ = it.next();
            var btn_it = std.mem.tokenizeScalar(u8, raw_btn[1 .. raw_btn.len - 1], ',');
            var btn_mask: usize = 0;
            while (btn_it.next()) |raw_toggle_idx| {
                const toggle_idx = try std.fmt.parseInt(u6, raw_toggle_idx, 10);

                btn_mask |= @as(usize, 1) << toggle_idx;
            }

            try buttons.append(btn_mask);
        }
        timer.reset();
        const runs = try runButtons(allocator, target, buttons.items);
        const duration = timer.read();
        std.log.debug("solved {s} ({b:0>8}) in {D}", .{ raw_target, target, duration });
        total_runs += runs;
    }

    std.log.info("{d}", .{total_runs});
}

fn runButtons(allocator: std.mem.Allocator, target: usize, buttons: []usize) !usize {
    const Item = struct { usize, usize };

    var q: std.array_list.Managed(Item) = try .initCapacity(allocator, 1024);
    defer q.deinit();

    var visited: std.AutoHashMap(usize, void) = .init(allocator);
    defer visited.deinit();

    try q.append(.{ 0, 0 }); // level 0, all lights off

    while (q.items.len > 0) {
        const level, const state = q.orderedRemove(0);
        try visited.put(state, {});

        const diff = state ^ target;

        for (buttons) |btn| {
            if (diff & btn == 0) // button does not resolve diff
                continue;

            const next_state = state ^ btn;
            if (next_state == target) return level + 1;

            if (visited.contains(next_state)) continue;
            try q.append(.{ level + 1, next_state });
        }
    }

    unreachable;
}
