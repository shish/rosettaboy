pub const GPU = struct {
    name: []const u8,
    headless: bool,
    debug: bool,

    pub fn new(name: []const u8, headless: bool, debug: bool) !GPU {
        return GPU{
            // FIXME
            .name = name,
            .headless = headless,
            .debug = debug,
        };
    }

    pub fn tick(self: GPU) !void {
        _ = self;
    }
};
