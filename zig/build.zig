const std = @import("std");
const sdl = @import("sdl");
//const sdl = @import("lib/sdl/Sdk.zig");

pub fn build(b: *std.Build) void {
    const sdk = sdl.init(b, .{});

    const exe = b.addExecutable(.{
        .name = "rosettaboy",
        .root_source_file = b.path("src/main.zig"),
        .target = b.graph.host,
    });

    const clap = b.dependency("clap", .{});
    exe.root_module.addImport("clap", clap.module("clap"));

    sdk.link(exe, .dynamic, sdl.Library.SDL2);
    exe.root_module.addImport("sdl2", sdk.getWrapperModule());

    b.installArtifact(exe);
}
