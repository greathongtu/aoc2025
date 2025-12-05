const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const max_size = 1024 * 1024;
    const content = try std.fs.cwd().readFileAlloc(allocator, "input.txt", max_size);
    defer allocator.free(content);

    std.debug.print("content: {s}\n", .{content});
}

fn turnLeft(current: u8, count: u8) u8 {
    if (current >= count) {
        return current - count;
    }
    return 100 - (count - current) % 100;
}

fn turnRight(current: u8, count: u8) u8 {
    return (current + count) % 100;
}
