const SDL = @import("sdl2");

pub const APU = struct {
    silent: bool,
    debug: bool,

    pub fn new(silent: bool, debug: bool) !APU {
        if (!silent) {
            try SDL.init(.{ .audio = true });
        }
        return APU{
            // FIXME
            .silent = silent,
            .debug = debug,
        };
    }
    pub fn tick(self: APU) !void {
        _ = self;
    }
};
