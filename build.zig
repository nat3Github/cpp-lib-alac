const std = @import("std");

// ponytail: only the C DSP core; ALACDecoder.cpp / ALACEncoder.cpp are ported to Zig in module/src.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{ .target = target, .optimize = optimize, .link_libc = true });
    mod.addIncludePath(b.path("codec"));
    // The core relies on wrapping signed shifts and unaligned uint32 loads (both UB in C), which
    // UBSan traps in Debug/ReleaseSafe; the other UBSan checks stay on.
    mod.addCSourceFiles(.{ .root = b.path("codec"), .flags = &.{ "-fwrapv", "-fno-sanitize=shift,alignment" }, .files = &.{
        "ag_dec.c",
        "ag_enc.c",
        "dp_dec.c",
        "dp_enc.c",
        "matrix_dec.c",
        "matrix_enc.c",
        "ALACBitUtilities.c",
        "EndianPortable.c",
    } });

    const lib = b.addLibrary(.{ .name = "alac", .root_module = mod });
    for ([_][]const u8{ "aglib.h", "dplib.h", "matrixlib.h", "ALACBitUtilities.h", "EndianPortable.h", "ALACAudioTypes.h" }) |h|
        lib.installHeader(b.path(b.fmt("codec/{s}", .{h})), b.fmt("alac/{s}", .{h}));
    b.installArtifact(lib);
}
