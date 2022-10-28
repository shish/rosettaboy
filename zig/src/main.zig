const std = @import("std");
const Args = @import("args.zig").Args;
const GameBoy = @import("gameboy.zig").GameBoy;
const errors = @import("errors.zig");
const SDL = @import("sdl2");

//pub const log_level: std.log.Level = .debug;
pub const scope_levels = [_]std.log.ScopeLevel{
    .{ .scope = .sdl2, .level = .debug },
    //.{ .scope = .library_b, .level = .crit },
};

pub fn main() anyerror!void {
    var args = try Args.parse_args();

    try SDL.init(.{
        .video = !args.headless,
        .audio = !args.silent,
        .events = true,
    });
    defer SDL.quit();

    // FIXME: catch errors, return appropriate exit codes
    var gameboy: GameBoy = undefined;
    try gameboy.init(args);
    gameboy.run() catch |err| {
        switch (err) {
            errors.ControlledExit.UnitTestPassed => {
                std.debug.print("Unit Test Passed\n", .{});
                std.os.exit(0);
            },
            errors.ControlledExit.UnitTestFailed => {
                std.debug.print("Unit Test Failed\n", .{});
                std.os.exit(2);
            },
            errors.ControlledExit.Timeout => {
                // the place that we raise this prints the output
                std.os.exit(0);
            },
            errors.ControlledExit.Quit => {
                std.os.exit(0);
            },
            // FIXME: match by error group?
            // errors.GameException => {
            //     std.debug.print("Game error\n", .{});
            //     std.os.exit(3);
            // },
            // errors.UserException => {
            //     std.debug.print("User error\n", .{});
            //     std.os.exit(4);
            // },
            SDL.Error.SdlError => {
                std.log.err("SDL error {any}\n", .{err});
                std.os.exit(99);
            },
            else => {
                std.log.err("Unknown error {any}\n", .{err});
                std.os.exit(5);
            },
        }
    };
    std.os.exit(1);
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
