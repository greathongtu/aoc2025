const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const max_size = 1024 * 1024;
    const content = try std.fs.cwd().readFileAlloc(allocator, "input.txt", max_size);
    defer allocator.free(content);

    var lines = std.mem.splitScalar(u8, content, '\n');

    var res: u32 = 0;
    var curr: u16 = 50;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (line[0] == 'L') {
            const cnt = try std.fmt.parseInt(u16, line[1..], 10);
            curr = turnLeft(curr, cnt);
        } else if (line[0] == 'R') {
            const cnt = try std.fmt.parseInt(u16, line[1..], 10);
            curr = turnRight(curr, cnt);
        }
        std.debug.assert(curr < 100);
        if (curr == 0) {
            res += 1;
        }
    }
    std.debug.print("Result: {d}\n", .{res});
}

fn turnLeft(current: u16, count: u16) u16 {
    if (current >= count) {
        return current - count;
    }
    var res = 100 - (count - current) % 100;
    if (res == 100) {
        res = 0;
    }
    return res;
}

fn turnRight(current: u16, count: u16) u16 {
    return (current + count) % 100;
}
