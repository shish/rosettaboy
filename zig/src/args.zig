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

    pub fn parse_args() Args {
        return Args{
            // FIXME
            .rom = "test.gb",
            .headless = true,
            .silent = true,
            .debug_cpu = false,
            .debug_gpu = false,
            .debug_apu = false,
            .debug_ram = false,
            .profile = 0,
            .turbo = false,
        };
    }
};
