const clap = @import("clap");
const std = @import("std");

const errors = @import("errors.zig");

const debug = std.debug;
const io = std.io;

pub const Args = struct {
    rom: []const u8,
    headless: bool,
    silent: bool,
    debug_cpu: bool,
    debug_gpu: bool,
    debug_apu: bool,
    debug_ram: bool,
    profile: u32,
    turbo: bool,

    pub fn parse_args() !Args {
        const params = comptime [_]clap.Param(clap.Help){
            clap.parseParam("-h, --help             Display this help and exit.") catch unreachable,
            clap.parseParam("-H, --headless         Disable GUI") catch unreachable,
            clap.parseParam("-S, --silent           Disable Sound") catch unreachable,
            clap.parseParam("-c, --debug-cpu        Debug CPU") catch unreachable,
            clap.parseParam("-g, --debug-gpu        Debug GPU") catch unreachable,
            clap.parseParam("-a, --debug-apu        Debug APU") catch unreachable,
            clap.parseParam("-r, --debug-ram        Debug RAM") catch unreachable,
            clap.parseParam("-p, --profile <NUM>    Exit after N frames") catch unreachable,
            clap.parseParam("-t, --turbo            No sleep()") catch unreachable,
            clap.parseParam("<POS>                  ROM filename") catch unreachable,
        };

        var diag = clap.Diagnostic{};
        var args = clap.parse(clap.Help, &params, .{ .diagnostic = &diag }) catch |err| {
            // Report useful error and exit
            diag.report(io.getStdErr().writer(), err) catch {};
            return err;
        };
        defer args.deinit();

        if (args.flag("--help")) {
            try clap.help(std.io.getStdErr().writer(), &params);
            return errors.ControlledExit.Help;
        }

        var profile: u32 = 0;
        if (args.option("--profile")) |n|
            profile = try std.fmt.parseInt(u32, n, 10);

        var rom: []const u8 = "";
        for (args.positionals()) |pos|
            rom = pos;

        return Args{
            .rom = rom,
            .headless = args.flag("--headless"),
            .silent = args.flag("--silent"),
            .debug_cpu = args.flag("--debug-cpu"),
            .debug_gpu = args.flag("--debug-gpu"),
            .debug_apu = args.flag("--debug-apu"),
            .debug_ram = args.flag("--debug-ram"),
            .profile = profile,
            .turbo = args.flag("--turbo"),
        };
    }
};
