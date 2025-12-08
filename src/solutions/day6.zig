const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
    .part2Fn = part2,
};

fn part1(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day6.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [4096]u8 = undefined; // a full line needs to be buffered
    var in = handle.reader(&buff);

    var numbers: std.array_list.Managed(usize) = .init(allocator);
    defer numbers.deinit();
    var w: usize = 0;
    var knows_w = false;
    var result: usize = 0;

    while (true) {
        const line = in.interface.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };

        var it = std.mem.tokenizeScalar(u8, line, ' ');
        var op_idx: usize = 0;

        while (it.next()) |token| {
            switch (token[0]) {
                '+', '*' => {
                    std.debug.assert(knows_w);

                    var sum = numbers.items[op_idx];
                    var i = op_idx + w;
                    while (i < numbers.items.len) {
                        if (token[0] == '+') {
                            sum += numbers.items[i];
                        }
                        if (token[0] == '*') {
                            sum *= numbers.items[i];
                        }
                        i += w;
                    }

                    result += sum;
                    op_idx += 1;
                },
                else => {
                    const n = try std.fmt.parseInt(usize, token, 10);
                    try numbers.append(n);
                    if (!knows_w) w += 1;
                },
            }
        }
        knows_w = true;
    }

    std.log.info("{d}", .{result});
}

fn part2(allocator: std.mem.Allocator) !void {
    var handle = try std.fs.cwd().openFileZ("./inputs/day6.txt", .{ .mode = .read_only });
    defer handle.close();

    var in = handle.reader(&.{});
    const txt = try in.interface.allocRemaining(allocator, .unlimited);
    defer allocator.free(txt);

    const last_line_idx = std.mem.lastIndexOfScalar(u8, txt, '\n').? + 1;

    var it = std.mem.tokenizeScalar(u8, txt[last_line_idx..], ' ');
    var result: usize = 0;
    while (it.next()) |token| {
        var buff: [8]u8 = undefined;
        var sum: usize = parseNumber(txt, &buff, it.index, 0) catch unreachable;
        var offset: usize = 1;

        while (true) {
            const n = parseNumber(txt, &buff, it.index, offset) catch |err| {
                switch (err) {
                    error.InvalidCharacter => break,
                    else => return err,
                }
            };

            switch (token[0]) {
                '+' => sum += n,
                '*' => sum *= n,
                else => unreachable,
            }

            offset += 1;
        }
        result += sum;
    }
    std.log.info("{d}", .{result});
}

fn parseNumber(txt: []const u8, buff: []u8, op_index: usize, offset: usize) !usize {
    const lines = std.mem.count(u8, txt, "\n");
    const w = std.mem.indexOfScalar(u8, txt, '\n').?;

    std.debug.assert(buff.len >= lines);
    for (0..lines) |i| {
        const idx = (i * w + i) + (op_index - 1) + offset;
        buff[i] = txt[idx];
    }

    return try std.fmt.parseInt(usize, std.mem.trim(u8, buff[0..lines], " \n"), 10);
}
