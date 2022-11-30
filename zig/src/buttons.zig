const SDL = @import("sdl2");

const errors = @import("errors.zig");
const consts = @import("consts.zig");
const CPU = @import("cpu.zig").CPU;
const RAM = @import("ram.zig").RAM;

const Joypad = struct {
    const MODE_BUTTONS: u8 = 1 << 5;
    const MODE_DPAD: u8 = 1 << 4;
    const DOWN: u8 = 1 << 3;
    const START: u8 = 1 << 3;
    const UP: u8 = 1 << 2;
    const SELECT: u8 = 1 << 2;
    const LEFT: u8 = 1 << 1;
    const B: u8 = 1 << 1;
    const RIGHT: u8 = 1 << 0;
    const A: u8 = 1 << 0;
    const BUTTON_BITS: u8 = 0b00001111;
};

pub const Buttons = struct {
    cpu: *CPU,
    ram: *RAM,
    turbo: bool,

    cycle: u32,
    up: bool,
    down: bool,
    left: bool,
    right: bool,
    a: bool,
    b: bool,
    start: bool,
    select: bool,

    pub fn new(cpu: *CPU, ram: *RAM, headless: bool) !Buttons {
        if (!headless) {
            try SDL.init(.{ .game_controller = true });
        }
        return Buttons{
            .cpu = cpu,
            .ram = ram,
            .turbo = false,
            .cycle = 0,
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
        if (self.cycle % 17556 == 20) {
            if (try self.handle_inputs()) {
                self.cpu.stop = false;
                self.cpu.interrupt(consts.Interrupt.JOYPAD);
            }
        }
    }

    pub fn update_buttons(self: *Buttons) void {
        var joyp = ~self.ram.get(consts.Mem.JOYP);
        joyp &= 0x30;
        if (joyp & Joypad.MODE_DPAD != 0) {
            if (self.up) joyp |= Joypad.UP;
            if (self.down) joyp |= Joypad.DOWN;
            if (self.left) joyp |= Joypad.LEFT;
            if (self.right) joyp |= Joypad.RIGHT;
        }
        if (joyp & Joypad.MODE_BUTTONS != 0) {
            if (self.b) joyp |= Joypad.B;
            if (self.a) joyp |= Joypad.A;
            if (self.start) joyp |= Joypad.START;
            if (self.select) joyp |= Joypad.SELECT;
        }
        self.ram.set(consts.Mem.JOYP, ~joyp & 0x3F);
    }

    pub fn handle_inputs(self: *Buttons) !bool {
        var need_interrupt = false;

        while (SDL.pollEvent()) |ev| {
            switch (ev) {
                .quit => return errors.ControlledExit.Quit,
                .key_down => {
                    need_interrupt = true;
                    switch (ev.key_down.keycode) {
                        SDL.Keycode.escape => return errors.ControlledExit.Quit,
                        SDL.Keycode.left_shift => {
                            self.turbo = true;
                            need_interrupt = false;
                        },
                        SDL.Keycode.up => self.up = true,
                        SDL.Keycode.down => self.down = true,
                        SDL.Keycode.left => self.left = true,
                        SDL.Keycode.right => self.right = true,
                        SDL.Keycode.z => self.b = true,
                        SDL.Keycode.x => self.a = true,
                        SDL.Keycode.@"return" => self.start = true,
                        SDL.Keycode.space => self.select = true,
                        else => {
                            need_interrupt = false;
                        },
                    }
                },
                .key_up => {
                    need_interrupt = true;
                    switch (ev.key_up.keycode) {
                        SDL.Keycode.left_shift => self.turbo = false,
                        SDL.Keycode.up => self.up = false,
                        SDL.Keycode.down => self.down = false,
                        SDL.Keycode.left => self.left = false,
                        SDL.Keycode.right => self.right = false,
                        SDL.Keycode.z => self.b = false,
                        SDL.Keycode.x => self.a = false,
                        SDL.Keycode.@"return" => self.start = false,
                        SDL.Keycode.space => self.select = false,
                        else => {},
                    }
                },
                else => {},
            }
        }

        return need_interrupt;
    }
};
