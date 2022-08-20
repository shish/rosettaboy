pub const APU = struct {
    silent: bool,
    debug: bool,

    pub fn new(silent: bool, debug: bool) !APU {
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
