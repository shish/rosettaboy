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
    const args = Args.parse_args() catch |err| {
        switch (err) {
            errors.ControlledExit.Help => {
                std.process.exit(0);
            },
            else => {
                std.log.err("Unknown error {any}\n", .{err});
                std.process.exit(5);
            },
        }
    };

    defer SDL.quit();

    // FIXME: catch errors, return appropriate exit codes
    var gameboy: GameBoy = undefined;
    try gameboy.init(args);
    gameboy.run() catch |err| {
        switch (err) {
            errors.ControlledExit.UnitTestPassed => {
                try std.io.getStdOut().writer().print("Unit test passed\n", .{});
                std.process.exit(0);
            },
            errors.ControlledExit.UnitTestFailed => {
                try std.io.getStdOut().writer().print("Unit test failed\n", .{});
                std.process.exit(2);
            },
            errors.ControlledExit.Timeout => {
                // the place that we raise this prints the output
                std.process.exit(0);
            },
            errors.ControlledExit.Quit => {
                std.process.exit(0);
            },
            errors.ControlledExit.Help => {
                std.process.exit(0);
            },
            // FIXME: match by error group?
            // errors.GameException => {
            //     std.io.getStdOut().writer().print("Game error\n", .{});
            //     std.process.exit(3);
            // },
            // errors.UserException => {
            //     std.io.getStdOut().writer().print("User error\n", .{});
            //     std.process.exit(4);
            // },
            SDL.Error.SdlError => {
                std.log.err("SDL error {any}\n", .{err});
                std.process.exit(99);
            },
            else => {
                std.log.err("Unknown error {any}\n", .{err});
                std.process.exit(5);
            },
        }
    };
    std.process.exit(1);
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
