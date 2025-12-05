const std = @import("std");

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

    var lines = std.mem.splitScalar(u8, content, '\n');

    var res: u32 = 0;
    var curr: u16 = 50;
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var times: u16 = 0;
        if (line[0] == 'L') {
            const cnt = try std.fmt.parseInt(u16, line[1..], 10);
            times = turnLeft(&curr, cnt);
        } else if (line[0] == 'R') {
            const cnt = try std.fmt.parseInt(u16, line[1..], 10);
            times = turnRight(&curr, cnt);
        }
        std.debug.assert(curr < 100);
        res += times;
    }
    std.debug.print("Result: {d}\n", .{res});
}

fn turnLeft(current: *u16, distance: u16) u16 {
    if (current.* >= distance) {
        const times: u16 = if (current.* == distance) 1 else 0;
        current.* = current.* - distance;
        return times;
    }

    if (current.* == 0) {
        const times = distance / 100;
        current.* = 100 - distance % 100;
        if (current.* == 100) {
            current.* = 0;
        }
        return times;
    }

    const times = 1 + (distance - current.*) / 100;
    current.* = 100 - (distance - current.*) % 100;
    if (current.* == 100) {
        current.* = 0;
    }

    return times;
}

fn turnRight(current: *u16, distance: u16) u16 {
    const times = (current.* + distance) / 100;
    current.* = (current.* + distance) % 100;
    return times;
}

test "iterate over an array" {
    try day1("test.txt");
}
