const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
    .part2Fn = part2,
};

fn part1(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day4.txt", .{ .mode = .read_only });
    defer handle.close();

    var in = handle.reader(&.{});

    const raw_grid = try in.interface.readAlloc(allocator, try in.getSize());
    defer allocator.free(raw_grid);

    const w = std.mem.indexOf(u8, raw_grid, "\n").?;

    const grid = try std.mem.replaceOwned(u8, allocator, raw_grid, "\n", "");
    defer allocator.free(grid);

    const result = try allocator.alloc(u8, grid.len);
    defer allocator.free(result);
    // must be a square
    std.debug.assert(grid.len == w * w);

    std.log.info("{d}", .{executeProcess(w, grid, result)});
}

const directions = [_]struct { isize, isize }{
    .{ -1, 0 },
    .{ 1, 0 },
    .{ 0, -1 },
    .{ 0, 1 },
    .{ -1, 1 },
    .{ -1, -1 },
    .{ 1, 1 },
    .{ 1, -1 },
};

fn part2(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day4.txt", .{ .mode = .read_only });
    defer handle.close();

    var in = handle.reader(&.{});

    const raw_grid = try in.interface.readAlloc(allocator, try in.getSize());
    defer allocator.free(raw_grid);

    const w = std.mem.indexOf(u8, raw_grid, "\n").?;

    const grid = try std.mem.replaceOwned(u8, allocator, raw_grid, "\n", "");
    defer allocator.free(grid);
    // must be a square
    std.debug.assert(grid.len == w * w);

    const result = try allocator.alloc(u8, grid.len);
    defer allocator.free(result);

    var total_removed: usize = 0;
    while (true) {
        const removed = executeProcess(w, grid, result);
        if (removed == 0)
            break;

        @memcpy(grid, result);
        total_removed += removed;
    }
    std.log.info("{d}", .{total_removed});
}

fn executeProcess(w: usize, grid: []u8, result: []u8) usize {
    @memcpy(result, grid);
    var accesible: usize = 0;
    for (0.., grid) |pos, tile| {
        if (tile != '@')
            continue;

        const x = pos % w;

        const y = @divFloor(pos, w);

        var adjacent_rolls_of_paper: usize = 0;
        for (directions) |offset| {
            const new_x = @as(isize, @intCast(x)) + offset.@"0";
            const new_y = @as(isize, @intCast(y)) + offset.@"1";

            if (new_x < 0) continue;
            if (new_x >= w) continue;
            if (new_y < 0) continue;
            if (new_y >= w) continue;

            const new_pos: usize = @as(usize, @intCast(new_y)) * w + @as(usize, @intCast(new_x));
            if (grid[new_pos] == '@')
                adjacent_rolls_of_paper += 1;
        }
        if (adjacent_rolls_of_paper < 4) {
            accesible += 1;
            result[pos] = '.';
        }
    }

    return accesible;
}
