const std = @import("std");

const MOD: u32 = 100;
const START_POS: u32 = 50;

const RotationResult = struct {
    pos: u32,
    zero_hits: u32,
};

pub fn main() !void {
    try day1("input.txt");
}

fn day1(fileName: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const max_size = 1024 * 1024;
    const content = try std.fs.cwd().readFileAlloc(allocator, fileName, max_size);
    defer allocator.free(content);

    const res = try count_password(content);
    std.debug.print("Result: {d}\n", .{res});
}

fn count_password(content: []const u8) !u64 {
    var lines = std.mem.splitScalar(u8, content, '\n');

    var pos: u32 = START_POS;
    var total: u64 = 0;

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const dir = line[0];
        const digits = line[1..];
        const dist = try std.fmt.parseInt(u32, digits, 10);

        var result: RotationResult = undefined;
        switch (dir) {
            'L' => result = rotate_left(pos, dist),
            'R' => result = rotate_right(pos, dist),
            else => return error.InvalidDirection,
        }
        pos = result.pos;
        total += @as(u64, result.zero_hits);
    }
    return total;
}

fn rotate_right(pos: u32, dist: u32) RotationResult {
    const total: u32 = pos + dist;
    const hits: u32 = total / MOD;
    const new_pos: u32 = total % MOD;
    return .{ .pos = new_pos, .zero_hits = hits };
}

fn rotate_left(pos: u32, dist: u32) RotationResult {
    if (pos == 0) {
        const hits: u32 = dist / MOD;
        const rem: u32 = dist % MOD;
        const res_pos: u32 = (MOD - rem) % MOD;
        return .{ .pos = res_pos, .zero_hits = hits };
    }

    if (dist < pos) {
        return .{ .pos = pos - dist, .zero_hits = 0 };
    }

    const over: u32 = dist - pos;
    const hits: u32 = 1 + over / MOD;
    const rem: u32 = over % MOD;
    const res_pos: u32 = (MOD - rem) % MOD;
    return .{ .pos = res_pos, .zero_hits = hits };
}

test "iterate over an array" {
    try day1("test.txt");
}
