const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const max_size = 1024 * 1024;
    const content = try std.fs.cwd().readFileAlloc(allocator, "input.txt", max_size);
    defer allocator.free(content);

    var res: u64 = 0;
    var lines = std.mem.splitScalar(u8, content, ',');

    while (lines.next()) |line| {
        var parts = std.mem.splitScalar(u8, line, '-');
        const raw_min = parts.next().?;
        const min = std.fmt.parseInt(u64, raw_min, 10) catch |err| {
            std.debug.print("Error parsing min: {s}, err: {s}\n", .{ raw_min, @errorName(err) });
            return err;
        };

        const raw_max = parts.next().?;
        const raw_max_trimmed = std.mem.trimEnd(u8, raw_max, "\n");
        const max = std.fmt.parseInt(u64, raw_max_trimmed, 10) catch |err| {
            std.debug.print("Error parsing max: {s}, err: {s}\n", .{ raw_max_trimmed, @errorName(err) });
            return err;
        };
        for (min..max + 1) |value| {
            if (isInvalid(value)) {
                res += value;
            }
        }
    }
    std.debug.print("Result: {d}\n", .{res});
}

fn isInvalid(value: usize) bool {
    var buf: [32]u8 = undefined;
    const full_str = std.fmt.bufPrint(&buf, "{}", .{value}) catch unreachable;

    for (1..full_str.len / 2 + 1) |i| {
        if (findOne(full_str, full_str[0..i])) {
            return true;
        }
    }

    return false;
}

fn findOne(full: []const u8, unit: []const u8) bool {
    if (full.len < unit.len or full.len % unit.len != 0) {
        return false;
    }

    var i: usize = 0;
    while (i < full.len) : (i += unit.len) {
        if (!std.mem.eql(u8, full[i .. i + unit.len], unit)) {
            return false;
        }
    }

    return true;
}
