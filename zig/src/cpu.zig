const consts = @import("consts.zig");

pub const CPU = packed struct {
    regs: packed union {
        r16: packed struct {
            af: u16,
            bc: u16,
            de: u16,
            hl: u16,
        },
        r8: packed struct {
            f: u8,
            a: u8,
            c: u8,
            b: u8,
            e: u8,
            d: u8,
            l: u8,
            h: u8,
        },
        flags: packed struct {
            _p1: u4,
            c: bool,
            h: bool,
            n: bool,
            z: bool,
            _p2: u56,
        },
    },
    sp: u16,
    pc: u16,
    stop: bool,
    halt: bool,
    interrupts: bool,

    debug: bool,
    cycle: u32,
    owed_cycles: u32,

    pub fn new(debug: bool) !CPU {
        return CPU{
            .regs = undefined,
            .sp = 0,
            .pc = 0,
            .stop = false,
            .halt = false,
            .interrupts = false,
            .debug = debug,
            .cycle = 0,
            .owed_cycles = 0,
        };
    }

    pub fn tick(self: *CPU) !void {
        _ = self;
    }

    pub fn interrupt(self: *CPU, i: u8) void {
        _ = self;
        _ = i;
    }
};
