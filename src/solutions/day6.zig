const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
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

    std.log.debug("{d}", .{result});
}
