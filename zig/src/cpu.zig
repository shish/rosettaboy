pub const CPU = struct {
    debug: bool,
    pub fn new(debug: bool) !CPU {
        return CPU{
            .debug = debug,
            // FIXME
        };
    }

    pub fn tick(self: CPU) !void {
        _ = self;
    }
};
