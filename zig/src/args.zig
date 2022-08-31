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
            clap.parseParam("-p, --profile <u32>    Exit after N frames") catch unreachable,
            clap.parseParam("-t, --turbo            No sleep()") catch unreachable,
            clap.parseParam("<str>                  ROM filename") catch unreachable,
        };

        var diag = clap.Diagnostic{};
        var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag, }) catch |err| {
            // Report useful error and exit
            diag.report(io.getStdErr().writer(), err) catch {};
            return err;
        };
        defer res.deinit();

        if (res.args.help) {
            try clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
            return errors.ControlledExit.Help;
        }

        var profile: u32 = 0;
        if (res.args.profile) |n|
            profile = n;

        var rom: []const u8 = "";
        for (res.positionals) |pos|
            rom = pos;

        return Args{
            .rom = rom,
            .headless = res.args.headless,
            .silent = res.args.silent,
            .debug_cpu = res.args.@"debug-cpu",
            .debug_gpu = res.args.@"debug-gpu",
            .debug_apu = res.args.@"debug-apu",
            .debug_ram = res.args.@"debug-ram",
            .profile = profile,
            .turbo = res.args.turbo,
        };
    }
};
