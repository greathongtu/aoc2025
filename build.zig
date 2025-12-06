const std = @import("std");

// 发现 src/dayXX 目录名（复制字符串到给定分配器）
fn discoverDays(alloc: std.mem.Allocator) ![]const []const u8 {
    var list = std.ArrayListUnmanaged([]const u8){};

    const cwd = std.fs.cwd();
    var dir = try cwd.openDir("src", .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind == .directory and std.mem.startsWith(u8, entry.name, "day")) {
            const name_copy = try copySliceAlloc(alloc, entry.name);
            try list.append(alloc, name_copy);
        }
    }
    return try list.toOwnedSlice(alloc);
}

fn hasDay(days: []const []const u8, name: []const u8) bool {
    for (days) |d| {
        if (std.mem.eql(u8, d, name)) return true;
    }
    return false;
}

// 判断某 day 是否存在 part 源文件
fn partExists(root: []const u8, day_name: []const u8, part: u8) bool {
    const name = if (part == 1) "part1.zig" else "part2.zig";
    const path = std.fs.path.join(std.heap.page_allocator, &.{ root, day_name, name }) catch return false;
    defer std.heap.page_allocator.free(path);

    const cwd = std.fs.cwd();
    // 如果 stat 成功，返回 true；出错（不存在等）则返回 false
    _ = cwd.statFile(path) catch return false;
    return true;
}

// 复制切片到分配器
fn copySliceAlloc(alloc: std.mem.Allocator, s: []const u8) ![]const u8 {
    const buf = try alloc.alloc(u8, s.len);
    @memcpy(buf, s);
    return buf;
}

// 为 day+part 添加可执行
fn addDayPartExe(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    day_name: []const u8,
    part: u8,
) *std.Build.Step.Compile {
    const exe_name = b.fmt("{s}-part{d}", .{ day_name, part });
    const rel = b.pathJoin(&.{ "src", day_name, if (part == 1) "part1.zig" else "part2.zig" });

    const exe = b.addExecutable(.{
        .name = exe_name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(rel),
            .target = target,
            .optimize = optimize,
        }),
    });
    return exe;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 可选参数：-Dday=day01 -Dpart=1|2
    const day_opt = b.option([]const u8, "day", "Day folder like 'day01'. If set, only build/run this day.");
    const part_opt = b.option(u8, "part", "Part number (1 or 2). Works with -Dday.");

    // 发现所有天（使用构建系统自带的分配器）
    const alloc = b.allocator;
    const days = discoverDays(alloc) catch {
        std.debug.print("Failed to discover days\n", .{});
        return;
    };

    // 安装所有生成的 exe
    const install_all = b.getInstallStep();

    if (day_opt) |day_name| {
        const PartSel = enum { both, one, two };
        const parts: PartSel = if (part_opt) |p| switch (p) {
            1 => .one,
            2 => .two,
            else => @panic("part must be 1 or 2"),
        } else .both;

        if (!hasDay(days, day_name)) {
            std.debug.print("Day '{s}' not found in src/\n", .{day_name});
            return;
        }

        if (parts == .one or parts == .both) {
            const exe1 = addDayPartExe(b, target, optimize, day_name, 1);
            b.installArtifact(exe1);
            install_all.dependOn(&exe1.step);

            const run_step1 = b.step(b.fmt("{s}-part1", .{day_name}), b.fmt("Run {s} part1", .{day_name}));
            const run_cmd1 = b.addRunArtifact(exe1);
            run_cmd1.cwd = b.path(b.pathJoin(&.{ "inputs", day_name }));
            run_step1.dependOn(&run_cmd1.step);

            if (parts == .one) {
                const run = b.step("run", "Run selected day/part");
                run.dependOn(&run_cmd1.step);
            }
        }
        if (parts == .two or parts == .both) {
            const exe2 = addDayPartExe(b, target, optimize, day_name, 2);
            b.installArtifact(exe2);
            install_all.dependOn(&exe2.step);

            const run_step2 = b.step(b.fmt("{s}-part2", .{day_name}), b.fmt("Run {s} part2", .{day_name}));
            const run_cmd2 = b.addRunArtifact(exe2);
            run_cmd2.cwd = b.path(b.pathJoin(&.{ "inputs", day_name }));
            run_step2.dependOn(&run_cmd2.step);

            if (parts == .two) {
                const run = b.step("run", "Run selected day/part");
                run.dependOn(&run_cmd2.step);
            }
        }
    } else {
        // 为所有 day 生成（若存在 part 源文件）
        for (days) |day_name| {
            var made_any = false;

            if (partExists("src", day_name, 1)) {
                const exe1 = addDayPartExe(b, target, optimize, day_name, 1);
                b.installArtifact(exe1);

                const run_step1 = b.step(b.fmt("{s}-part1", .{day_name}), b.fmt("Run {s} part1", .{day_name}));
                const run_cmd1 = b.addRunArtifact(exe1);
                run_cmd1.cwd = b.path(b.pathJoin(&.{ "inputs", day_name }));
                run_step1.dependOn(&run_cmd1.step);

                made_any = true;
            }
            if (partExists("src", day_name, 2)) {
                const exe2 = addDayPartExe(b, target, optimize, day_name, 2);
                b.installArtifact(exe2);
                install_all.dependOn(&exe2.step);

                const run_step2 = b.step(b.fmt("{s}-part2", .{day_name}), b.fmt("Run {s} part2", .{day_name}));
                const run_cmd2 = b.addRunArtifact(exe2);
                run_cmd2.cwd = b.path(b.pathJoin(&.{ "inputs", day_name }));
                run_step2.dependOn(&run_cmd2.step);

                made_any = true;
            }

            if (!made_any) {
                std.debug.print("Warning: {s} has no part1.zig/part2.zig\n", .{day_name});
            }
        }
    }
}
