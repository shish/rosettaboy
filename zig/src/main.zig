const std = @import("std");
const Args = @import("args.zig").Args;
const GameBoy = @import("gameboy.zig").GameBoy;
const errors = @import("errors.zig");
const SDL = @import("sdl2");

pub fn main() anyerror!void {
    var args = try Args.parse_args();

    try SDL.init(.{
        .video = !args.headless,
        .audio = !args.silent,
        .events = true,
    });
    defer SDL.quit();

    // TODO: catch errors, don't print a stack trace for
    // ControlledExit variants
    var gameboy = try GameBoy.new(args);
    try gameboy.run();
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
