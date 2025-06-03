const std = @import("std");

const RAM = @import("ram.zig").RAM;
const consts = @import("consts.zig");
const errors = @import("errors.zig");

pub const OP_CYCLES = [_]u8{
    // 1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    1, 3, 2, 2, 1, 1, 2, 1, 5, 2, 2, 2, 1, 1, 2, 1, // 0
    0, 3, 2, 2, 1, 1, 2, 1, 3, 2, 2, 2, 1, 1, 2, 1, // 1
    2, 3, 2, 2, 1, 1, 2, 1, 2, 2, 2, 2, 1, 1, 2, 1, // 2
    2, 3, 2, 2, 3, 3, 3, 1, 2, 2, 2, 2, 1, 1, 2, 1, // 3
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 4
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 5
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 6
    2, 2, 2, 2, 2, 2, 0, 2, 1, 1, 1, 1, 1, 1, 2, 1, // 7
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 8
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 9
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // A
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // B
    2, 3, 3, 4, 3, 4, 2, 4, 2, 4, 3, 0, 3, 6, 2, 4, // C
    2, 3, 3, 0, 3, 4, 2, 4, 2, 4, 3, 0, 3, 0, 2, 4, // D
    3, 3, 2, 0, 0, 4, 2, 4, 4, 1, 4, 0, 0, 0, 2, 4, // E
    3, 3, 2, 1, 0, 4, 2, 4, 3, 2, 4, 1, 0, 0, 2, 4, // F
};

pub const OP_CB_CYCLES = [_]u8{
    // 1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 0
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 1
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 2
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 3
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, // 4
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, // 5
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, // 6
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, // 7
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 8
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 9
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // A
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // B
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // C
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // D
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // E
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // F
};

pub const OP_TYPES = [_]u2{
    // 1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 2, 0, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 1, 0, // 0
    1, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, // 1
    3, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, // 2
    3, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, // 3
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 4
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 5
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 6
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 7
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // A
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // B
    0, 0, 2, 2, 2, 0, 1, 0, 0, 0, 2, 0, 2, 2, 1, 0, // C
    0, 0, 2, 0, 2, 0, 1, 0, 0, 0, 2, 0, 2, 0, 1, 0, // D
    1, 0, 0, 0, 0, 0, 1, 0, 3, 0, 2, 0, 0, 0, 1, 0, // E
    1, 0, 0, 0, 0, 0, 1, 0, 3, 0, 2, 0, 0, 0, 1, 0, // F
};

// no arg, u8, u16, i8
pub const OP_ARG_BYTES = [_]u2{ 0, 1, 2, 1 };

pub const OP_NAMES = [_][]const u8{
    "NOP",          "LD BC,$u16", "LD [BC],A",   "INC BC",    "INC B",        "DEC B",     "LD B,$u8",    "RCLA",
    "LD [$u16],SP", "ADD HL,BC",  "LD A,[BC]",   "DEC BC",    "INC C",        "DEC C",     "LD C,$u8",    "RRCA",
    "STOP",         "LD DE,$u16", "LD [DE],A",   "INC DE",    "INC D",        "DEC D",     "LD D,$u8",    "RLA",
    "JR i8",        "ADD HL,DE",  "LD A,[DE]",   "DEC DE",    "INC E",        "DEC E",     "LD E,$u8",    "RRA",
    "JR NZ,i8",     "LD HL,$u16", "LD [HL+],A",  "INC HL",    "INC H",        "DEC H",     "LD H,$u8",    "DAA",
    "JR Z,i8",      "ADD HL,HL",  "LD A,[HL+]",  "DEC HL",    "INC L",        "DEC L",     "LD L,$u8",    "CPL",
    "JR NC,i8",     "LD SP,$u16", "LD [HL-],A",  "INC SP",    "INC [HL]",     "DEC [HL]",  "LD [HL],$u8", "SCF",
    "JR C,i8",      "ADD HL,SP",  "LD A,[HL-]",  "DEC SP",    "INC A",        "DEC A",     "LD A,$u8",    "CCF",
    "LD B,B",       "LD B,C",     "LD B,D",      "LD B,E",    "LD B,H",       "LD B,L",    "LD B,[HL]",   "LD B,A",
    "LD C,B",       "LD C,C",     "LD C,D",      "LD C,E",    "LD C,H",       "LD C,L",    "LD C,[HL]",   "LD C,A",
    "LD D,B",       "LD D,C",     "LD D,D",      "LD D,E",    "LD D,H",       "LD D,L",    "LD D,[HL]",   "LD D,A",
    "LD E,B",       "LD E,C",     "LD E,D",      "LD E,E",    "LD E,H",       "LD E,L",    "LD E,[HL]",   "LD E,A",
    "LD H,B",       "LD H,C",     "LD H,D",      "LD H,E",    "LD H,H",       "LD H,L",    "LD H,[HL]",   "LD H,A",
    "LD L,B",       "LD L,C",     "LD L,D",      "LD L,E",    "LD L,H",       "LD L,L",    "LD L,[HL]",   "LD L,A",
    "LD [HL],B",    "LD [HL],C",  "LD [HL],D",   "LD [HL],E", "LD [HL],H",    "LD [HL],L", "HALT",        "LD [HL],A",
    "LD A,B",       "LD A,C",     "LD A,D",      "LD A,E",    "LD A,H",       "LD A,L",    "LD A,[HL]",   "LD A,A",
    "ADD A,B",      "ADD A,C",    "ADD A,D",     "ADD A,E",   "ADD A,H",      "ADD A,L",   "ADD A,[HL]",  "ADD A,A",
    "ADC A,B",      "ADC A,C",    "ADC A,D",     "ADC A,E",   "ADC A,H",      "ADC A,L",   "ADC A,[HL]",  "ADC A,A",
    "SUB A,B",      "SUB A,C",    "SUB A,D",     "SUB A,E",   "SUB A,H",      "SUB A,L",   "SUB A,[HL]",  "SUB A,A",
    "SBC A,B",      "SBC A,C",    "SBC A,D",     "SBC A,E",   "SBC A,H",      "SBC A,L",   "SBC A,[HL]",  "SBC A,A",
    "AND B",        "AND C",      "AND D",       "AND E",     "AND H",        "AND L",     "AND [HL]",    "AND A",
    "XOR B",        "XOR C",      "XOR D",       "XOR E",     "XOR H",        "XOR L",     "XOR [HL]",    "XOR A",
    "OR B",         "OR C",       "OR D",        "OR E",      "OR H",         "OR L",      "OR [HL]",     "OR A",
    "CP B",         "CP C",       "CP D",        "CP E",      "CP H",         "CP L",      "CP [HL]",     "CP A",
    "RET NZ",       "POP BC",     "JP NZ,$u16",  "JP $u16",   "CALL NZ,$u16", "PUSH BC",   "ADD A,$u8",   "RST 00",
    "RET Z",        "RET",        "JP Z,$u16",   "ERR CB",    "CALL Z,$u16",  "CALL $u16", "ADC A,$u8",   "RST 08",
    "RET NC",       "POP DE",     "JP NC,$u16",  "ERR D3",    "CALL NC,$u16", "PUSH DE",   "SUB A,$u8",   "RST 10",
    "RET C",        "RETI",       "JP C,$u16",   "ERR DB",    "CALL C,$u16",  "ERR DD",    "SBC A,$u8",   "RST 18",
    "LDH [$u8],A",  "POP HL",     "LDH [C],A",   "DBG",       "ERR E4",       "PUSH HL",   "AND $u8",     "RST 20",
    "ADD SP i8",    "JP HL",      "LD [$u16],A", "ERR EB",    "ERR EC",       "ERR ED",    "XOR $u8",     "RST 28",
    "LDH A,[$u8]",  "POP AF",     "LDH A,[C]",   "DI",        "ERR F4",       "PUSH AF",   "OR $u8",      "RST 30",
    "LD HL,SPi8",   "LD SP,HL",   "LD A,[$u16]", "EI",        "ERR FC",       "ERR FD",    "CP $u8",      "RST 38",
};

pub const OP_CB_NAMES = [_][]const u8{
    "RLC B",   "RLC C",   "RLC D",   "RLC E",   "RLC H",   "RLC L",   "RLC [HL]",   "RLC A",
    "RRC B",   "RRC C",   "RRC D",   "RRC E",   "RRC H",   "RRC L",   "RRC [HL]",   "RRC A",
    "RL B",    "RL C",    "RL D",    "RL E",    "RL H",    "RL L",    "RL [HL]",    "RL A",
    "RR B",    "RR C",    "RR D",    "RR E",    "RR H",    "RR L",    "RR [HL]",    "RR A",
    "SLA B",   "SLA C",   "SLA D",   "SLA E",   "SLA H",   "SLA L",   "SLA [HL]",   "SLA A",
    "SRA B",   "SRA C",   "SRA D",   "SRA E",   "SRA H",   "SRA L",   "SRA [HL]",   "SRA A",
    "SWAP B",  "SWAP C",  "SWAP D",  "SWAP E",  "SWAP H",  "SWAP L",  "SWAP [HL]",  "SWAP A",
    "SRL B",   "SRL C",   "SRL D",   "SRL E",   "SRL H",   "SRL L",   "SRL [HL]",   "SRL A",
    "BIT 0,B", "BIT 0,C", "BIT 0,D", "BIT 0,E", "BIT 0,H", "BIT 0,L", "BIT 0,[HL]", "BIT 0,A",
    "BIT 1,B", "BIT 1,C", "BIT 1,D", "BIT 1,E", "BIT 1,H", "BIT 1,L", "BIT 1,[HL]", "BIT 1,A",
    "BIT 2,B", "BIT 2,C", "BIT 2,D", "BIT 2,E", "BIT 2,H", "BIT 2,L", "BIT 2,[HL]", "BIT 2,A",
    "BIT 3,B", "BIT 3,C", "BIT 3,D", "BIT 3,E", "BIT 3,H", "BIT 3,L", "BIT 3,[HL]", "BIT 3,A",
    "BIT 4,B", "BIT 4,C", "BIT 4,D", "BIT 4,E", "BIT 4,H", "BIT 4,L", "BIT 4,[HL]", "BIT 4,A",
    "BIT 5,B", "BIT 5,C", "BIT 5,D", "BIT 5,E", "BIT 5,H", "BIT 5,L", "BIT 5,[HL]", "BIT 5,A",
    "BIT 6,B", "BIT 6,C", "BIT 6,D", "BIT 6,E", "BIT 6,H", "BIT 6,L", "BIT 6,[HL]", "BIT 6,A",
    "BIT 7,B", "BIT 7,C", "BIT 7,D", "BIT 7,E", "BIT 7,H", "BIT 7,L", "BIT 7,[HL]", "BIT 7,A",
    "RES 0,B", "RES 0,C", "RES 0,D", "RES 0,E", "RES 0,H", "RES 0,L", "RES 0,[HL]", "RES 0,A",
    "RES 1,B", "RES 1,C", "RES 1,D", "RES 1,E", "RES 1,H", "RES 1,L", "RES 1,[HL]", "RES 1,A",
    "RES 2,B", "RES 2,C", "RES 2,D", "RES 2,E", "RES 2,H", "RES 2,L", "RES 2,[HL]", "RES 2,A",
    "RES 3,B", "RES 3,C", "RES 3,D", "RES 3,E", "RES 3,H", "RES 3,L", "RES 3,[HL]", "RES 3,A",
    "RES 4,B", "RES 4,C", "RES 4,D", "RES 4,E", "RES 4,H", "RES 4,L", "RES 4,[HL]", "RES 4,A",
    "RES 5,B", "RES 5,C", "RES 5,D", "RES 5,E", "RES 5,H", "RES 5,L", "RES 5,[HL]", "RES 5,A",
    "RES 6,B", "RES 6,C", "RES 6,D", "RES 6,E", "RES 6,H", "RES 6,L", "RES 6,[HL]", "RES 6,A",
    "RES 7,B", "RES 7,C", "RES 7,D", "RES 7,E", "RES 7,H", "RES 7,L", "RES 7,[HL]", "RES 7,A",
    "SET 0,B", "SET 0,C", "SET 0,D", "SET 0,E", "SET 0,H", "SET 0,L", "SET 0,[HL]", "SET 0,A",
    "SET 1,B", "SET 1,C", "SET 1,D", "SET 1,E", "SET 1,H", "SET 1,L", "SET 1,[HL]", "SET 1,A",
    "SET 2,B", "SET 2,C", "SET 2,D", "SET 2,E", "SET 2,H", "SET 2,L", "SET 2,[HL]", "SET 2,A",
    "SET 3,B", "SET 3,C", "SET 3,D", "SET 3,E", "SET 3,H", "SET 3,L", "SET 3,[HL]", "SET 3,A",
    "SET 4,B", "SET 4,C", "SET 4,D", "SET 4,E", "SET 4,H", "SET 4,L", "SET 4,[HL]", "SET 4,A",
    "SET 5,B", "SET 5,C", "SET 5,D", "SET 5,E", "SET 5,H", "SET 5,L", "SET 5,[HL]", "SET 5,A",
    "SET 6,B", "SET 6,C", "SET 6,D", "SET 6,E", "SET 6,H", "SET 6,L", "SET 6,[HL]", "SET 6,A",
    "SET 7,B", "SET 7,C", "SET 7,D", "SET 7,E", "SET 7,H", "SET 7,L", "SET 7,[HL]", "SET 7,A",
};

pub const OpArg = packed union {
    u8: u8, // B
    i8: i8, // b
    u16: u16, // H
};

fn flag(ien: u8, ifl: u8, i: u8, c: u8) u8 {
    if (ien & i != 0) {
        if (ifl & i != 0) {
            return c & '_'; // set uppercase ASCII flag
        } else {
            return c;
        }
    } else {
        return '_';
    }
}

pub const CPU = struct {
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

    ram: *RAM,
    debug: bool,
    cycle: u32,
    owed_cycles: u32,

    pub fn new(ram: *RAM, debug: bool) !CPU {
        return CPU{
            .regs = .{
                .r16 = .{
                    .af = 0,
                    .bc = 0,
                    .de = 0,
                    .hl = 0,
                },
            },
            .sp = 0,
            .pc = 0,
            .stop = false,
            .halt = false,
            .ram = ram,
            .interrupts = false,
            .debug = debug,
            .cycle = 0,
            .owed_cycles = 0,
        };
    }

    pub fn interrupt(self: *CPU, i: u8) void {
        self.ram.set(consts.Mem.IF, self.ram.get(consts.Mem.IF) | i);
        self.halt = false; // interrupts interrupt HALT state
    }

    pub fn tick(self: *CPU) !void {
        self.tick_dma();
        self.tick_clock();
        self.tick_interrupts();
        if (self.halt) {
            return;
        }
        if (self.stop) {
            return;
        }
        try self.tick_instructions();
    }

    fn dump_regs(self: *CPU) !void {
        // stack
        const sp_val = @as(u16, @intCast(self.ram.get(self.sp))) | @as(u16, @intCast(self.ram.get(self.sp + 1))) << 8;

        // interrupts
        const z: u8 = if (self.regs.flags.z) 'Z' else 'z';
        const n: u8 = if (self.regs.flags.n) 'N' else 'n';
        const c: u8 = if (self.regs.flags.c) 'C' else 'c';
        const h: u8 = if (self.regs.flags.h) 'H' else 'h';

        const ien = self.ram.get(consts.Mem.IE);
        const ifl = self.ram.get(consts.Mem.IF);
        const v = flag(ien, ifl, consts.Interrupt.VBLANK, 'v');
        const l = flag(ien, ifl, consts.Interrupt.STAT, 'l');
        const t = flag(ien, ifl, consts.Interrupt.TIMER, 't');
        const s = flag(ien, ifl, consts.Interrupt.SERIAL, 's');
        const j = flag(ien, ifl, consts.Interrupt.JOYPAD, 'j');

        // opcode & args
        var op = self.ram.get(self.pc);
        var op_str: [16]u8 = "                ".*;
        if (op == 0xCB) {
            op = self.ram.get(self.pc + 1);
            @memcpy(op_str[0..], OP_CB_NAMES[op][0..]);
        } else {
            const base = OP_NAMES[op][0..];
            const arg = self.load_op(self.pc + 1, OP_TYPES[op]);
            switch (OP_TYPES[op]) {
                0 => {
                    @memcpy(op_str[0..], base);
                },
                1 => {
                    var param = "  ".*;
                    _ = try std.fmt.bufPrint(&param, "{X:0>2}", .{arg.u8});
                    _ = std.mem.replace(u8, base, "u8", &param, &op_str);
                },
                2 => {
                    var param = "    ".*;
                    _ = try std.fmt.bufPrint(&param, "{X:0>4}", .{arg.u16});
                    _ = std.mem.replace(u8, base, "u16", &param, &op_str);
                },
                3 => {
                    var param = "    ".*;
                    if (arg.i8 > 0) {
                        _ = try std.fmt.bufPrint(&param, "+{d}", .{arg.i8});
                    } else {
                        _ = try std.fmt.bufPrint(&param, "{d}", .{arg.i8});
                    }
                    _ = std.mem.replace(u8, base, "i8", &param, &op_str);
                },
            }
        }

        // print
        try std.io.getStdOut().writer().print("{X:0>4} {X:0>4} {X:0>4} {X:0>4} : ", .{ self.regs.r16.af, self.regs.r16.bc, self.regs.r16.de, self.regs.r16.hl });
        try std.io.getStdOut().writer().print("{X:0>4} = {X:0>4} : ", .{ self.sp, sp_val });
        try std.io.getStdOut().writer().print("{c}{c}{c}{c} : {c}{c}{c}{c}{c} : ", .{ z, n, h, c, v, l, t, s, j });
        try std.io.getStdOut().writer().print("{X:0>4} = {X:0>2} : {s}\n", .{ self.pc, op, op_str });
    }

    fn tick_dma(self: *CPU) void {
        // TODO: DMA should take 26 cycles, during which main RAM is inaccessible
        if (self.ram.get(consts.Mem.DMA) != 0) {
            const dma_src: u16 = @as(u16, @intCast(self.ram.get(consts.Mem.DMA))) << 8;

            var i: u16 = 0;
            while (i <= 0xA0) : (i += 1) {
                self.ram.set(consts.Mem.OamBase + i, self.ram.get(dma_src + i));
            }
            self.ram.set(consts.Mem.DMA, 0x00);
        }
    }

    fn tick_clock(self: *CPU) void {
        self.cycle += 1;

        // TODO: writing any value to consts.Mem.DIV should reset it to 0x00
        // increment at 16384Hz (each 64 cycles?)
        if (self.cycle % 64 == 0) {
            self.ram.set(consts.Mem.DIV, self.ram.get(consts.Mem.DIV) +% 1);
        }

        if (self.ram.get(consts.Mem.TAC) & 1 << 2 == 1 << 2) {
            // timer enable
            const speeds = [_]u16{ 256, 4, 16, 64 }; // increment per X cycles
            const speed = speeds[(self.ram.get(consts.Mem.TAC) & 0x03)];
            if (self.cycle % speed == 0) {
                if (self.ram.get(consts.Mem.TIMA) == 0xFF) {
                    self.ram.set(consts.Mem.TIMA, self.ram.get(consts.Mem.TMA)); // if timer overflows, load base
                    self.interrupt(consts.Interrupt.TIMER);
                }
                self.ram.set(consts.Mem.TIMA, self.ram.get(consts.Mem.TIMA) +% 1);
            }
        }
    }

    fn check_interrupts(self: *CPU, queue: u8, i: u8, handler: u16) bool {
        if (queue & i != 0) {
            // TODO: wait two cycles
            // TODO: push16(PC) should also take two cycles
            // TODO: one more cycle to store new PC
            self.push(self.pc);
            self.pc = handler;
            self.ram.set(consts.Mem.IF, self.ram.get(consts.Mem.IF) & ~i);
            return true;
        }
        return false;
    }

    fn tick_interrupts(self: *CPU) void {
        const queue = self.ram.get(consts.Mem.IE) & self.ram.get(consts.Mem.IF);
        if (self.interrupts and queue != 0) {
            if (self.debug) {
                std.io.getStdOut().writer().print("Handling interrupts: {X:0>2} & {X:0>2}\n", .{ self.ram.get(consts.Mem.IE), self.ram.get(consts.Mem.IF) }) catch return;
            }

            // no nested interrupts, RETI will re-enable
            self.interrupts = false;
            _ = self.check_interrupts(queue, consts.Interrupt.VBLANK, consts.Mem.VBlankHandler) or
                self.check_interrupts(queue, consts.Interrupt.STAT, consts.Mem.LcdHandler) or
                self.check_interrupts(queue, consts.Interrupt.TIMER, consts.Mem.TimerHandler) or
                self.check_interrupts(queue, consts.Interrupt.SERIAL, consts.Mem.SerialHandler) or
                self.check_interrupts(queue, consts.Interrupt.JOYPAD, consts.Mem.JoypadHandler);
        }
    }

    fn tick_instructions(self: *CPU) !void {
        // if the previous instruction was large, let's not run any
        // more instructions until other subsystems have caught up
        if (self.owed_cycles > 0) {
            self.owed_cycles -= 1;
            return;
        }

        if (self.debug) {
            try self.dump_regs();
        }

        var op = self.ram.get(self.pc);
        if (op == 0xCB) {
            op = self.ram.get(self.pc + 1);
            self.pc += 2;
            self.tick_cb(op);
            self.owed_cycles = OP_CB_CYCLES[op];
        } else {
            const arg_type = OP_TYPES[op];
            const arg_len = OP_ARG_BYTES[arg_type];
            const arg = self.load_op(self.pc + 1, arg_type);
            self.pc += 1 + arg_len;
            try self.tick_main(op, arg);
            self.owed_cycles = OP_CYCLES[op];
        }

        // HALT has cycles=0
        if (self.owed_cycles > 0) {
            self.owed_cycles -= 1;
        }
    }

    fn load_op(self: *CPU, addr: u16, arg_type: u2) OpArg {
        return switch (arg_type) {
            0 => OpArg{
                .u16 = 0,
            },
            1 => OpArg{
                .u8 = self.ram.get(addr),
            },
            2 => OpArg{
                .u16 = @as(u16, @intCast(self.ram.get(addr))) | @as(u16, @intCast(self.ram.get(addr + 1))) << 8,
            },
            3 => OpArg{
                .i8 = @as(i8, @bitCast(self.ram.get(addr))),
            },
        };
    }

    fn tick_main(self: *CPU, op: u8, arg: OpArg) !void {
        switch (op) {
            0x00 => {}, // NOP
            0x01 => {
                self.regs.r16.bc = arg.u16;
            },
            0x02 => {
                self.ram.set(self.regs.r16.bc, self.regs.r8.a);
            },
            0x03 => {
                self.regs.r16.bc = self.regs.r16.bc +% 1;
            },
            0x08 => {
                self.ram.set(arg.u16 + 1, @as(u8, @intCast((self.sp >> 8) & 0xFF)));
                self.ram.set(arg.u16, @as(u8, @intCast(self.sp & 0xFF)));
            }, // how does this fit?
            0x0A => {
                self.regs.r8.a = self.ram.get(self.regs.r16.bc);
            },
            0x0B => {
                self.regs.r16.bc = self.regs.r16.bc -% 1;
            },

            0x10 => {
                self.stop = true;
            },
            0x11 => {
                self.regs.r16.de = arg.u16;
            },
            0x12 => {
                self.ram.set(self.regs.r16.de, self.regs.r8.a);
            },
            0x13 => {
                self.regs.r16.de = self.regs.r16.de +% 1;
            },
            0x18 => {
                self.pc = @as(u16, @intCast(@as(i32, @intCast(self.pc)) + arg.i8));
            },
            0x1A => {
                self.regs.r8.a = self.ram.get(self.regs.r16.de);
            },
            0x1B => {
                self.regs.r16.de = self.regs.r16.de -% 1;
            },

            0x20 => {
                if (!self.regs.flags.z) {
                    self.pc = @as(u16, @intCast(@as(i32, @intCast(self.pc)) + arg.i8));
                }
            },
            0x21 => {
                self.regs.r16.hl = arg.u16;
            },
            0x22 => {
                self.ram.set(self.regs.r16.hl, self.regs.r8.a);
                self.regs.r16.hl = self.regs.r16.hl +% 1;
            },
            0x23 => {
                self.regs.r16.hl = self.regs.r16.hl +% 1;
            },
            0x27 => {
                var val16: u16 = self.regs.r8.a;
                if (!self.regs.flags.n) {
                    if (self.regs.flags.h or (val16 & 0x0F) > 9) {
                        val16 = val16 +% 6;
                    }
                    if (self.regs.flags.c or val16 > 0x9F) {
                        val16 = val16 +% 0x60;
                    }
                } else {
                    if (self.regs.flags.h) {
                        val16 = val16 -% 6;
                        if (!self.regs.flags.c) {
                            val16 &= 0xFF;
                        }
                    }
                    if (self.regs.flags.c) {
                        val16 = val16 -% 0x60;
                    }
                }
                self.regs.flags.h = false;
                if (val16 & 0x100 != 0) {
                    self.regs.flags.c = true;
                }
                self.regs.r8.a = @as(u8, @intCast(val16 & 0xFF));
                self.regs.flags.z = self.regs.r8.a == 0;
            },
            0x28 => {
                if (self.regs.flags.z) {
                    self.pc = @as(u16, @intCast(@as(i32, @intCast(self.pc)) + arg.i8));
                }
            },
            0x2A => {
                self.regs.r8.a = self.ram.get(self.regs.r16.hl);
                self.regs.r16.hl = self.regs.r16.hl +% 1;
            },
            0x2B => {
                self.regs.r16.hl = self.regs.r16.hl -% 1;
            },
            0x2F => {
                self.regs.r8.a ^= 0xFF;
                self.regs.flags.n = true;
                self.regs.flags.h = true;
            },

            0x30 => {
                if (!self.regs.flags.c) {
                    self.pc = @as(u16, @intCast(@as(i32, @intCast(self.pc)) + arg.i8));
                }
            },
            0x31 => {
                self.sp = arg.u16;
            },
            0x32 => {
                self.ram.set(self.regs.r16.hl, self.regs.r8.a);
                self.regs.r16.hl = self.regs.r16.hl -% 1;
            },
            0x33 => {
                self.sp = self.sp +% 1;
            },
            0x37 => {
                self.regs.flags.n = false;
                self.regs.flags.h = false;
                self.regs.flags.c = true;
            },
            0x38 => {
                if (self.regs.flags.c) {
                    self.pc = @as(u16, @intCast(@as(i32, @intCast(self.pc)) + arg.i8));
                }
            },
            0x3A => {
                self.regs.r8.a = self.ram.get(self.regs.r16.hl);
                self.regs.r16.hl = self.regs.r16.hl -% 1;
            },
            0x3B => {
                self.sp = self.sp -% 1;
            },
            0x3F => {
                self.regs.flags.c = !self.regs.flags.c;
                self.regs.flags.n = false;
                self.regs.flags.h = false;
            },

            // INC r
            0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x34, 0x3C => {
                const val = self.get_reg((op - 0x04) / 8);
                self.regs.flags.h = (val & 0x0F) == 0x0F;
                self.regs.flags.z = val +% 1 == 0;
                self.regs.flags.n = false;
                self.set_reg((op - 0x04) / 8, val +% 1);
            },

            // DEC r
            0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D => {
                const val = self.get_reg((op - 0x05) / 8);
                self.regs.flags.h = (val -% 1 & 0x0F) == 0x0F;
                self.regs.flags.z = val -% 1 == 0;
                self.regs.flags.n = true;
                self.set_reg((op - 0x05) / 8, val -% 1);
            },

            // LD r,n
            0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E => {
                self.set_reg((op - 0x06) / 8, arg.u8);
            },

            // RCLA, RLA, RRCA, RRA
            0x07, 0x17, 0x0F, 0x1F => {
                const carry: u8 = if (self.regs.flags.c) 1 else 0;
                if (op == 0x07) {
                    // RCLA
                    self.regs.flags.c = (self.regs.r8.a & 1 << 7) != 0;
                    self.regs.r8.a = (self.regs.r8.a << 1) | (self.regs.r8.a >> 7);
                }
                if (op == 0x17) {
                    // RLA
                    self.regs.flags.c = (self.regs.r8.a & 1 << 7) != 0;
                    self.regs.r8.a = (self.regs.r8.a << 1) | carry;
                }
                if (op == 0x0F) {
                    // RRCA
                    self.regs.flags.c = (self.regs.r8.a & 1 << 0) != 0;
                    self.regs.r8.a = (self.regs.r8.a >> 1) | (self.regs.r8.a << 7);
                }
                if (op == 0x1F) {
                    // RRA
                    self.regs.flags.c = (self.regs.r8.a & 1 << 0) != 0;
                    self.regs.r8.a = (self.regs.r8.a >> 1) | (carry << 7);
                }
                self.regs.flags.n = false;
                self.regs.flags.h = false;
                self.regs.flags.z = false;
            },

            // ADD HL,rr
            0x09, 0x19, 0x29, 0x39 => {
                const val16 = switch (op) {
                    0x09 => self.regs.r16.bc,
                    0x19 => self.regs.r16.de,
                    0x29 => self.regs.r16.hl,
                    0x39 => self.sp,
                    else => 0,
                };
                self.regs.flags.h = (self.regs.r16.hl & 0x0FFF) + (val16 & 0x0FFF) > 0x0FFF;
                self.regs.flags.c = (@as(u32, @intCast(self.regs.r16.hl)) + @as(u32, @intCast(val16))) > 0xFFFF;
                self.regs.r16.hl = self.regs.r16.hl +% val16;
                self.regs.flags.n = false;
            },

            0x40...0x7F => {
                // LD r,r
                if (op == 0x76) {
                    // FIXME: weird timing side effects
                    self.halt = true;
                }
                self.set_reg((op - 0x40) >> 3, self.get_reg(op - 0x40));
            },

            // <math> <reg>
            0x80...0x87 => self._add(self.get_reg(op)),
            0x88...0x8F => self._adc(self.get_reg(op)),
            0x90...0x97 => self._sub(self.get_reg(op)),
            0x98...0x9F => self._sbc(self.get_reg(op)),
            0xA0...0xA7 => self._and(self.get_reg(op)),
            0xA8...0xAF => self._xor(self.get_reg(op)),
            0xB0...0xB7 => self._or(self.get_reg(op)),
            0xB8...0xBF => self._cp(self.get_reg(op)),

            0xC0 => {
                if (!self.regs.flags.z) {
                    self.pc = self.pop();
                }
            },
            0xC1 => {
                self.regs.r16.bc = self.pop();
            },
            0xC2 => {
                if (!self.regs.flags.z) {
                    self.pc = arg.u16;
                }
            },
            0xC3 => {
                self.pc = arg.u16;
            },
            0xC4 => {
                if (!self.regs.flags.z) {
                    self.push(self.pc);
                    self.pc = arg.u16;
                }
            },
            0xC5 => {
                self.push(self.regs.r16.bc);
            },
            0xC6 => {
                self._add(arg.u8);
            },
            0xC7 => {
                self.push(self.pc);
                self.pc = 0x00;
            },
            0xC8 => {
                if (self.regs.flags.z) {
                    self.pc = self.pop();
                }
            },
            0xC9 => {
                self.pc = self.pop();
            },
            0xCA => {
                if (self.regs.flags.z) {
                    self.pc = arg.u16;
                }
            },
            0xCC => {
                if (self.regs.flags.z) {
                    self.push(self.pc);
                    self.pc = arg.u16;
                }
            },
            0xCD => {
                self.push(self.pc);
                self.pc = arg.u16;
            },
            0xCE => {
                self._adc(arg.u8);
            },
            0xCF => {
                self.push(self.pc);
                self.pc = 0x08;
            },

            0xD0 => {
                if (!self.regs.flags.c) {
                    self.pc = self.pop();
                }
            },
            0xD1 => {
                self.regs.r16.de = self.pop();
            },
            0xD2 => {
                if (!self.regs.flags.c) {
                    self.pc = arg.u16;
                }
            },
            0xD4 => {
                if (!self.regs.flags.c) {
                    self.push(self.pc);
                    self.pc = arg.u16;
                }
            },
            0xD5 => {
                self.push(self.regs.r16.de);
            },
            0xD6 => {
                self._sub(arg.u8);
            },
            0xD7 => {
                self.push(self.pc);
                self.pc = 0x10;
            },
            0xD8 => {
                if (self.regs.flags.c) {
                    self.pc = self.pop();
                }
            },
            0xD9 => {
                self.pc = self.pop();
                self.interrupts = true;
            },
            0xDA => {
                if (self.regs.flags.c) {
                    self.pc = arg.u16;
                }
            },
            0xDC => {
                if (self.regs.flags.c) {
                    self.push(self.pc);
                    self.pc = arg.u16;
                }
            },
            0xDE => {
                self._sbc(arg.u8);
            },
            0xDF => {
                self.push(self.pc);
                self.pc = 0x18;
            },

            0xE0 => {
                self.ram.set(0xFF00 + @as(u16, @intCast(arg.u8)), self.regs.r8.a);
                if (arg.u8 == 0x01) {
                    _ = std.c.printf("%c", self.regs.r8.a);
                }
            },
            0xE1 => {
                self.regs.r16.hl = self.pop();
            },
            0xE2 => {
                self.ram.set(0xFF00 + @as(u16, @intCast(self.regs.r8.c)), self.regs.r8.a);
                if (self.regs.r8.c == 0x01) {
                    _ = std.c.printf("%c", self.regs.r8.a);
                }
            },
            0xE5 => {
                self.push(self.regs.r16.hl);
            },
            0xE6 => {
                self._and(arg.u8);
            },
            0xE7 => {
                self.push(self.pc);
                self.pc = 0x20;
            },
            0xE8 => {
                const val16: u16 = @as(u16, @intCast(@as(i64, @intCast((@as(i32, @intCast(self.sp)) + arg.i8))) & 0xFFFF));
                self.regs.flags.h = ((self.sp ^ @as(u16, @bitCast(@as(i16, @intCast(arg.i8)))) ^ val16) & 0x10) != 0;
                self.regs.flags.c = ((self.sp ^ @as(u16, @bitCast(@as(i16, @intCast(arg.i8)))) ^ val16) & 0x100) != 0;
                self.sp = val16;
                self.regs.flags.z = false;
                self.regs.flags.n = false;
            },
            0xE9 => {
                self.pc = self.regs.r16.hl;
            },
            0xEA => {
                self.ram.set(arg.u16, self.regs.r8.a);
            },
            0xEE => {
                self._xor(arg.u8);
            },
            0xEF => {
                self.push(self.pc);
                self.pc = 0x28;
            },

            0xF0 => {
                self.regs.r8.a = self.ram.get(@as(u16, @intCast(0xFF00)) + arg.u8);
            },
            0xF1 => {
                self.regs.r16.af = self.pop() & 0xFFF0;
            },
            0xF2 => {
                self.regs.r8.a = self.ram.get(@as(u16, @intCast(0xFF00)) + self.regs.r8.c);
            },
            0xF3 => {
                self.interrupts = false;
            },
            0xF5 => {
                self.push(self.regs.r16.af);
            },
            0xF6 => self._or(arg.u8),
            0xF7 => {
                self.push(self.pc);
                self.pc = 0x30;
            },
            0xF8 => {
                const new_hl = @as(u16, @intCast(@as(i64, @intCast(@as(i32, @intCast(self.sp)) + arg.i8)) & 0xFFFF));
                if (arg.i8 >= 0) {
                    self.regs.flags.c = (@as(i32, @intCast(self.sp & 0xFF)) + (arg.i8)) > 0xFF;
                    self.regs.flags.h = (@as(i32, @intCast(self.sp & 0x0F)) + (arg.i8 & 0x0F)) > 0x0F;
                } else {
                    self.regs.flags.c = (new_hl & 0xFF) <= (self.sp & 0xFF);
                    self.regs.flags.h = (new_hl & 0x0F) <= (self.sp & 0x0F);
                }
                self.regs.r16.hl = new_hl;
                self.regs.flags.z = false;
                self.regs.flags.n = false;
            },
            0xF9 => self.sp = self.regs.r16.hl,
            0xFA => self.regs.r8.a = self.ram.get(arg.u16),
            0xFB => self.interrupts = true,
            0xFC => return errors.ControlledExit.UnitTestPassed, // unofficial
            0xFD => return errors.ControlledExit.UnitTestFailed, // unofficial
            0xFE => self._cp(arg.u8),
            0xFF => {
                self.push(self.pc);
                self.pc = 0x38;
            },
            else => {
                try std.io.getStdOut().writer().print("Invalid op: {X:0>2}\n", .{op});
                return errors.GameException.InvalidOpcode;
            },
        }
    }

    fn tick_cb(self: *CPU, op: u8) void {
        var val = self.get_reg(op);
        switch (op & 0xF8) {
            // RLC
            0x00...0x07 => {
                self.regs.flags.c = (val & 1 << 7) != 0;
                val <<= 1;
                if (self.regs.flags.c) {
                    val |= 1 << 0;
                }
                self.regs.flags.n = false;
                self.regs.flags.h = false;
                self.regs.flags.z = val == 0;
            },

            // RRC
            0x08...0x0F => {
                self.regs.flags.c = (val & 1 << 0) != 0;
                val >>= 1;
                if (self.regs.flags.c) {
                    val |= 1 << 7;
                }
                self.regs.flags.n = false;
                self.regs.flags.h = false;
                self.regs.flags.z = val == 0;
            },

            // RL
            0x10...0x17 => {
                const orig_c = self.regs.flags.c;
                self.regs.flags.c = (val & 1 << 7) != 0;
                val <<= 1;
                if (orig_c) {
                    val |= 1 << 0;
                }
                self.regs.flags.n = false;
                self.regs.flags.h = false;
                self.regs.flags.z = val == 0;
            },

            // RR
            0x18...0x1F => {
                const orig_c = self.regs.flags.c;
                self.regs.flags.c = (val & 1 << 0) != 0;
                val >>= 1;
                if (orig_c) {
                    val |= 1 << 7;
                }
                self.regs.flags.n = false;
                self.regs.flags.h = false;
                self.regs.flags.z = val == 0;
            },

            // SLA
            0x20...0x27 => {
                self.regs.flags.c = (val & 1 << 7) != 0;
                val <<= 1;
                val &= 0xFF;
                self.regs.flags.n = false;
                self.regs.flags.h = false;
                self.regs.flags.z = val == 0;
            },

            // SRA
            0x28...0x2F => {
                self.regs.flags.c = (val & 1 << 0) != 0;
                val >>= 1;
                if (val & 1 << 6 != 0) {
                    val |= 1 << 7;
                }
                self.regs.flags.n = false;
                self.regs.flags.h = false;
                self.regs.flags.z = val == 0;
            },

            // SWAP
            0x30...0x37 => {
                val = ((val & 0xF0) >> 4) | ((val & 0x0F) << 4);
                self.regs.flags.c = false;
                self.regs.flags.n = false;
                self.regs.flags.h = false;
                self.regs.flags.z = val == 0;
            },

            // SRL
            0x38...0x3F => {
                self.regs.flags.c = (val & 1 << 0) != 0;
                val >>= 1;
                self.regs.flags.n = false;
                self.regs.flags.h = false;
                self.regs.flags.z = val == 0;
            },

            // BIT
            0x40...0x7F => {
                const bit: u3 = @as(u3, @intCast((op & 0b00111000) >> 3));
                self.regs.flags.z = (val & (@as(u8, @intCast(1)) << bit)) == 0;
                self.regs.flags.n = false;
                self.regs.flags.h = true;
            },

            // RES
            0x80...0xBF => {
                const bit: u3 = @as(u3, @intCast((op & 0b00111000) >> 3));
                val &= (@as(u8, @intCast(1)) << bit) ^ 0xFF;
            },

            // SET
            0xC0...0xFF => {
                const bit: u3 = @as(u3, @intCast((op & 0b00111000) >> 3));
                val |= @as(u8, @intCast(1)) << bit;
            },
        }
        self.set_reg(op, val);
    }

    fn _xor(self: *CPU, val: u8) void {
        self.regs.r8.a ^= val;

        self.regs.flags.z = self.regs.r8.a == 0;
        self.regs.flags.n = false;
        self.regs.flags.h = false;
        self.regs.flags.c = false;
    }

    fn _or(self: *CPU, val: u8) void {
        self.regs.r8.a |= val;

        self.regs.flags.z = self.regs.r8.a == 0;
        self.regs.flags.n = false;
        self.regs.flags.h = false;
        self.regs.flags.c = false;
    }

    fn _and(self: *CPU, val: u8) void {
        self.regs.r8.a &= val;

        self.regs.flags.z = self.regs.r8.a == 0;
        self.regs.flags.n = false;
        self.regs.flags.h = true;
        self.regs.flags.c = false;
    }

    fn _cp(self: *CPU, val: u8) void {
        self.regs.flags.z = self.regs.r8.a == val;
        self.regs.flags.n = true;
        self.regs.flags.h = (self.regs.r8.a & 0x0F) < (val & 0x0F);
        self.regs.flags.c = self.regs.r8.a < val;
    }

    fn _add(self: *CPU, val: u8) void {
        self.regs.flags.c = @as(u16, @intCast(self.regs.r8.a)) + @as(u16, @intCast(val)) > 0xFF;
        self.regs.flags.h = (self.regs.r8.a & 0x0F) + (val & 0x0F) > 0x0F;
        self.regs.flags.n = false;
        self.regs.r8.a = self.regs.r8.a +% val;
        self.regs.flags.z = self.regs.r8.a == 0;
    }

    fn _adc(self: *CPU, val: u8) void {
        const carry: u8 = if (self.regs.flags.c) 1 else 0;
        self.regs.flags.c = @as(u16, @intCast(self.regs.r8.a)) + @as(u16, @intCast(val)) + @as(u16, @intCast(carry)) > 0xFF;
        self.regs.flags.h = (self.regs.r8.a & 0x0F) + (val & 0x0F) + carry > 0x0F;
        self.regs.flags.n = false;
        self.regs.r8.a = self
            .regs
            .r8
            .a +% val +% carry;
        self.regs.flags.z = self.regs.r8.a == 0;
    }

    fn _sub(self: *CPU, val: u8) void {
        self.regs.flags.c = self.regs.r8.a < val;
        self.regs.flags.h = (self.regs.r8.a & 0x0F) < (val & 0x0F);
        self.regs.r8.a = self.regs.r8.a -% val;
        self.regs.flags.z = self.regs.r8.a == 0;
        self.regs.flags.n = true;
    }

    fn _sbc(self: *CPU, val: u8) void {
        const carry: u8 = if (self.regs.flags.c) 1 else 0;
        const res: i16 = @as(i16, @intCast(self.regs.r8.a)) -% @as(i16, @intCast(val)) -% @as(i16, @intCast(carry));
        self.regs.flags.h = ((self.regs.r8.a ^ val ^ (res & 0xff)) & (1 << 4)) != 0;
        self.regs.flags.c = res < 0;
        self.regs.r8.a = self
            .regs
            .r8
            .a -% val -% carry;
        self.regs.flags.z = self.regs.r8.a == 0;
        self.regs.flags.n = true;
    }

    fn push(self: *CPU, val: u16) void {
        self.ram.set(self.sp - 1, @as(u8, @intCast(((val & 0xFF00) >> 8) & 0xFF)));
        self.ram.set(self.sp - 2, @as(u8, @intCast((val & 0xFF))));
        self.sp -= 2;
    }

    fn pop(self: *CPU) u16 {
        const val = (@as(u16, @intCast(self.ram.get(self.sp + 1))) << 8) | self.ram.get(self.sp);
        self.sp += 2;
        return val;
    }

    fn get_reg(self: *CPU, n: u8) u8 {
        return switch (@as(u3, @intCast(n & 0x07))) {
            0 => self.regs.r8.b,
            1 => self.regs.r8.c,
            2 => self.regs.r8.d,
            3 => self.regs.r8.e,
            4 => self.regs.r8.h,
            5 => self.regs.r8.l,
            6 => self.ram.get(self.regs.r16.hl),
            7 => self.regs.r8.a,
        };
    }

    fn set_reg(self: *CPU, n: u8, val: u8) void {
        switch (@as(u3, @intCast(n & 0x07))) {
            0 => self.regs.r8.b = val,
            1 => self.regs.r8.c = val,
            2 => self.regs.r8.d = val,
            3 => self.regs.r8.e = val,
            4 => self.regs.r8.h = val,
            5 => self.regs.r8.l = val,
            6 => self.ram.set(self.regs.r16.hl, val),
            7 => self.regs.r8.a = val,
        }
    }
};
