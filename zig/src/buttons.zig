pub const Buttons = struct {
    headless: bool,
    turbo: bool,

    pub fn new(headless: bool) !Buttons {
        return Buttons{
            // FIXME
            .headless = headless,
            .turbo = false,
        };
    }
    pub fn tick(self: Buttons) !void {
        _ = self;
    }
};
