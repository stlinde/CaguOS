const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    var target: std.zig.CrossTarget = .{
        .cpu_arch = .x86_64, // We're building a x86-64 OS
        .os_tag = .freestanding, // Kernel must be built freestanding - that is without stdlib etc.
        .abi = .none, // No ABI (Application Binary Interface)
    };

    // Disable CPU features that require additional initialization
    // like MMX, SSE/2 and AVX. That requires us to enable the soft-float feature.
    const Features = std.Target.x86.Feature;
    target.cpu_features_sub.addFeature(@intFromEnum(Features.mmx));
    target.cpu_features_sub.addFeature(@intFromEnum(Features.sse));
    target.cpu_features_sub.addFeature(@intFromEnum(Features.sse2));
    target.cpu_features_sub.addFeature(@intFromEnum(Features.avx));
    target.cpu_features_sub.addFeature(@intFromEnum(Features.avx2));
    target.cpu_features_add.addFeature(@intFromEnum(Features.soft_float));

    // Build the kernel itself.
    const optimize = b.standardOptimizeOption(.{});
    const limine = b.dependency("limine", .{});
    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = .{ .path = "src/kernel.zig" },
        .target = target,
        .optimize = optimize,
    });
    kernel.code_model = .kernel;
    kernel.addModule("limine", limine.module("limine"));
    kernel.setLinkerScriptPath(.{ .path = "linker.ld" });
    kernel.pie = true; // Set Position Independent Executable to true.

    b.installArtifact(kernel);
}
