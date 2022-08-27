const consts = @import("consts.zig");

pub const CPU = struct {
    debug: bool,
    stop: bool,
    pub fn new(debug: bool) !CPU {
        return CPU{
            .debug = debug,
            .stop = false,
            // FIXME
        };
    }

    pub fn tick(self: *CPU) !void {
        _ = self;
    }

    pub fn interrupt(self: *CPU, i: consts.Interrupt) void {
        _ = self;
        _ = i;
    }
};
