const std = @import("std");

const Solution = @import("../main.zig").Solution;

pub const solution: Solution = .{
    .part1Fn = part1,
    .part2Fn = part2,
};

fn part1(allocator: std.mem.Allocator) !void {
    _ = allocator;
    const Validator = struct {
        fn isValid(n: u64) bool {
            var buff: [64]u8 = undefined;
            const str = std.fmt.bufPrint(&buff, "{d}", .{n}) catch unreachable;

            const left = str[0 .. str.len / 2];
            const right = str[str.len / 2 ..];

            return !std.mem.eql(u8, left, right);
        }
    };

    var handle = try std.fs.cwd().openFileZ("./inputs/day2.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [128]u8 = undefined;
    var in = handle.reader(&buff);

    const sum = runValidation(&in.interface, Validator.isValid);
    std.log.debug("{d}", .{sum});
}

fn part2(allocator: std.mem.Allocator) !void {
    _ = allocator;
    const Validator = struct {
        fn isValid(n: u64) bool {
            var buff: [64]u8 = undefined;
            const str = std.fmt.bufPrint(&buff, "{d}", .{n}) catch unreachable;
            for (1..str.len) |i| next_pattern: {
                const pattern = str[0..i];
                if (@rem(str.len, pattern.len) != 0)
                    continue;

                var k = i;

                while (k <= str.len - pattern.len) {
                    const part = str[k .. k + pattern.len];

                    if (!std.mem.eql(u8, pattern, part)) {
                        break :next_pattern;
                    }
                    k += pattern.len;
                }
                return false;
            }
            return true;
        }
    };

    var handle = try std.fs.cwd().openFileZ("./inputs/day2.txt", .{ .mode = .read_only });
    defer handle.close();
    var buff: [128]u8 = undefined;
    var in = handle.reader(&buff);

    const sum = runValidation(&in.interface, Validator.isValid);
    std.log.debug("{d}", .{sum});
}

fn runValidation(in: *std.Io.Reader, isValidFn: *const fn (u64) bool) u64 {
    var sum: usize = 0;
    while (true) {
        const range = in.takeDelimiterExclusive(',') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => unreachable,
            }
        };

        var it = std.mem.splitScalar(u8, range, '-');
        const start = std.fmt.parseInt(u64, it.next().?, 10) catch unreachable;
        const end = std.fmt.parseInt(u64, it.next().?, 10) catch unreachable;
        std.debug.assert(it.next() == null);

        for (start..end + 1) |product_id| {
            if (!isValidFn(product_id)) {
                sum += product_id;
            }
        }
    }

    return sum;
}
