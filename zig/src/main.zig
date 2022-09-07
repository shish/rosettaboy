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

    // FIXME: catch errors, return appropriate exit codes
    var gameboy = try GameBoy.new(args);
    gameboy.run() catch |err| {
        if(err == errors.ControlledExit.UnitTestPassed) {
            std.debug.print("Unit Test Passed\n", .{});
            std.os.exit(0);
        }
    };
    std.os.exit(1);
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
