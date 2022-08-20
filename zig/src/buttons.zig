pub const Buttons = struct {
    headless: bool,

    pub fn new(headless: bool) !Buttons {
        return Buttons{
            // FIXME
            .headless = headless,
        };
    }
    pub fn tick(self: Buttons) !void {
        _ = self;
    }
};
