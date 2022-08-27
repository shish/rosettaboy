const consts = @import("consts.zig");
const CPU = @import("cpu.zig").CPU;
const RAM = @import("ram.zig").RAM;

pub const Buttons = struct {
    cpu: *CPU,
    ram: *RAM,
    headless: bool,
    turbo: bool,

    cycle: u32,
    need_interrupt: bool,
    up: bool,
    down: bool,
    left: bool,
    right: bool,
    a: bool,
    b: bool,
    start: bool,
    select: bool,

    pub fn new(cpu: *CPU, ram: *RAM, headless: bool) !Buttons {
        return Buttons{
            .cpu = cpu,
            .ram = ram,
            .headless = headless,
            .turbo = false,
            .cycle = 0,
            .need_interrupt = false,
            .up = false,
            .down = false,
            .left = false,
            .right = false,
            .a = false,
            .b = false,
            .start = false,
            .select = false,
        };
    }

    pub fn tick(self: *Buttons) !void {
        self.cycle += 1;
        self.update_buttons();
        if(self.need_interrupt) {
            self.cpu.stop = false;
            self.cpu.interrupt(consts.Interrupt.JOYPAD);
            self.need_interrupt = false;
        }
        if(self.cycle % 17556 == 20) {
            try self.handle_inputs();
        }
    }

    pub fn update_buttons(self: *Buttons) void {
        _ = self;
    }
    pub fn handle_inputs(self: *Buttons) !void {
        _ = self;
    }
};
