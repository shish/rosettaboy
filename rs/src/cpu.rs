use crate::consts::*;
use crate::ram;
use anyhow::{anyhow, Result};

pub const OP_CYCLES: [u32; 0x100] = [
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
];

pub const OP_CB_CYCLES: [u32; 0x100] = [
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
];

pub const OP_TYPES: [u8; 0x100] = [
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
];

// no arg, u8, u16, i8
pub const OP_LENS: [u16; 4] = [0, 1, 2, 1];

#[cfg_attr(rustfmt, rustfmt_skip)]
pub const OP_NAMES: [&str; 0x100] = [
    "NOP", "LD BC,nn", "LD [BC],A", "INC BC", "INC B", "DEC B", "LD B,n", "RCLA", "LD [nn],SP",
    "ADD HL,BC", "LD A,[BC]", "DEC BC", "INC C", "DEC C", "LD C,n", "RRCA", "STOP", "LD DE,nn",
    "LD [DE],A", "INC DE", "INC D", "DEC D", "LD D,n", "RLA", "JR %+d", "ADD HL,DE", "LD A,[DE]",
    "DEC DE", "INC E", "DEC E", "LD E,n", "RRA", "JR NZ,%+d", "LD HL,nn", "LD [HL+],A", "INC HL",
    "INC H", "DEC H", "LD H,n", "DAA", "JR Z,%+d", "ADD HL,HL", "LD A,[HL+]", "DEC HL", "INC L",
    "DEC L", "LD L,n", "CPL", "JR NC,%+d", "LD SP,nn", "LD [HL-],A", "INC SP", "INC [HL]",
    "DEC [HL]", "LD [HL],n", "SCF", "JR C,%+d", "ADD HL,SP", "LD A,[HL-]", "DEC SP", "INC A",
    "DEC A", "LD A,n", "CCF",
    "LD B,B", "LD B,C", "LD B,D", "LD B,E", "LD B,H", "LD B,L", "LD B,[HL]", "LD B,A",
    "LD C,B", "LD C,C", "LD C,D", "LD C,E", "LD C,H", "LD C,L", "LD C,[HL]", "LD C,A",
    "LD D,B", "LD D,C", "LD D,D", "LD D,E", "LD D,H", "LD D,L", "LD D,[HL]", "LD D,A",
    "LD E,B", "LD E,C", "LD E,D", "LD E,E", "LD E,H", "LD E,L", "LD E,[HL]", "LD E,A",
    "LD H,B", "LD H,C", "LD H,D", "LD H,E", "LD H,H", "LD H,L", "LD H,[HL]", "LD H,A",
    "LD L,B", "LD L,C", "LD L,D", "LD L,E", "LD L,H", "LD L,L", "LD L,[HL]", "LD L,A",
    "LD [HL],B", "LD [HL],C", "LD [HL],D", "LD [HL],E", "LD [HL],H", "LD [HL],L", "HALT", "LD [HL],A",
    "LD A,B", "LD A,C", "LD A,D", "LD A,E", "LD A,H", "LD A,L", "LD A,[HL]", "LD A,A",
    "ADD A,B", "ADD A,C", "ADD A,D", "ADD A,E", "ADD A,H", "ADD A,L", "ADD A,[HL]", "ADD A,A",
    "ADC A,B", "ADC A,C", "ADC A,D", "ADC A,E", "ADC A,H", "ADC A,L", "ADC A,[HL]", "ADC A,A",
    "SUB A,B", "SUB A,C", "SUB A,D", "SUB A,E", "SUB A,H", "SUB A,L", "SUB A,[HL]", "SUB A,A",
    "SBC A,B", "SBC A,C", "SBC A,D", "SBC A,E", "SBC A,H", "SBC A,L", "SBC A,[HL]", "SBC A,A",
    "AND B", "AND C", "AND D", "AND E", "AND H", "AND L", "AND [HL]", "AND A",
    "XOR B", "XOR C", "XOR D", "XOR E", "XOR H", "XOR L", "XOR [HL]", "XOR A",
    "OR B", "OR C", "OR D", "OR E", "OR H", "OR L", "OR [HL]", "OR A",
    "CP B", "CP C", "CP D", "CP E", "CP H", "CP L", "CP [HL]", "CP A",
    "RET NZ", "POP BC", "JP NZ,nn", "JP nn", "CALL NZ,nn", "PUSH BC", "ADD A,n", "RST 00",
    "RET Z", "RET", "JP Z,nn", "ERR CB", "CALL Z,nn", "CALL nn", "ADC A,n", "RST 08",
    "RET NC", "POP DE", "JP NC,nn", "ERR D3", "CALL NC,nn", "PUSH DE", "SUB A,n", "RST 10",
    "RET C", "RETI", "JP C,nn", "ERR DB", "CALL C,nn", "ERR DD", "SBC A,n", "RST 18",
    "LDH [n],A", "POP HL", "LDH [C],A", "DBG", "ERR E4", "PUSH HL", "AND n", "RST 20",
    "ADD SP %+d", "JP HL", "LD [nn],A", "ERR EB", "ERR EC", "ERR ED", "XOR n", "RST 28",
    "LDH A,[n]", "POP AF", "LDH A,[C]", "DI", "ERR F4", "PUSH AF", "OR n", "RST 30",
    "LD HL,SPn", "LD SP,HL", "LD A,[nn]", "EI", "ERR FC", "ERR FD", "CP n", "RST 38",
];

#[cfg_attr(rustfmt, rustfmt_skip)]
pub const OP_CB_NAMES: [&str; 0x100] = [
    "RLC B", "RLC C", "RLC D", "RLC E", "RLC H", "RLC L", "RLC [HL]", "RLC A",
    "RRC B", "RRC C", "RRC D", "RRC E", "RRC H", "RRC L", "RRC [HL]", "RRC A",
    "RL B", "RL C", "RL D", "RL E", "RL H", "RL L", "RL [HL]", "RL A",
    "RR B", "RR C", "RR D", "RR E", "RR H", "RR L", "RR [HL]", "RR A",
    "SLA B", "SLA C", "SLA D", "SLA E", "SLA H", "SLA L", "SLA [HL]", "SLA A",
    "SRA B", "SRA C", "SRA D", "SRA E", "SRA H", "SRA L", "SRA [HL]", "SRA A",
    "SWAP B", "SWAP C", "SWAP D", "SWAP E", "SWAP H", "SWAP L", "SWAP [HL]", "SWAP A",
    "SRL B", "SRL C", "SRL D", "SRL E", "SRL H", "SRL L", "SRL [HL]", "SRL A",
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
];

bitflags! {
    pub struct Flag: u8 {
        const Z = 1<<7;
        const N = 1<<6;
        const H = 1<<5;
        const C = 1<<4;
    }
}

struct OpArg {
    u8: u8,   // B
    i8: i8,   // b
    u16: u16, // H
}

#[derive(Copy, Clone, Debug)]
struct R8 {
    f: u8,
    a: u8,
    c: u8,
    b: u8,
    e: u8,
    d: u8,
    l: u8,
    h: u8,
}
#[derive(Copy, Clone, Debug)]
struct R16 {
    af: u16,
    bc: u16,
    de: u16,
    hl: u16,
}
union Regs {
    r8: R8,
    r16: R16,
}
pub struct CPU {
    pub stop: bool,
    interrupts: bool,
    halt: bool,
    debug: bool,
    cycle: u32,
    owed_cycles: u32,
    regs: Regs,
    sp: u16,
    pc: u16,
    flag_z: bool,
    flag_n: bool,
    flag_c: bool,
    flag_h: bool,
}

impl CPU {
    pub fn init(debug: bool) -> CPU {
        CPU {
            stop: false,

            interrupts: true,
            halt: false,
            debug,
            cycle: 0,
            owed_cycles: 0,

            regs: Regs {
                r16: R16 {
                    af: 0,
                    bc: 0,
                    de: 0,
                    hl: 0,
                },
            },
            sp: 0,
            pc: 0,
            // FIXME: flags should be a union with F register
            flag_z: false,
            flag_n: false,
            flag_c: false,
            flag_h: false,
        }
    }

    fn get_reg(&self, n: u8, ram: &ram::RAM) -> u8 {
        unsafe {
            match n % 8 {
                0 => self.regs.r8.b,
                1 => self.regs.r8.c,
                2 => self.regs.r8.d,
                3 => self.regs.r8.e,
                4 => self.regs.r8.h,
                5 => self.regs.r8.l,
                6 => ram.get(self.regs.r16.hl),
                7 => self.regs.r8.a,
                _ => panic!("Invalid register {}", n),
            }
        }
    }

    fn set_reg(&mut self, n: u8, val: u8, ram: &mut ram::RAM) {
        unsafe {
            match n % 8 {
                0 => self.regs.r8.b = val,
                1 => self.regs.r8.c = val,
                2 => self.regs.r8.d = val,
                3 => self.regs.r8.e = val,
                4 => self.regs.r8.h = val,
                5 => self.regs.r8.l = val,
                6 => ram.set(self.regs.r16.hl, val),
                7 => self.regs.r8.a = val,
                _ => panic!("Invalid register {}", n),
            }
        }
    }

    /**
     * Set a given interrupt bit - on the next tick, if the interrupt
     * handler for this interrupt is enabled (and interrupts in general
     * are enabled), then the interrupt handler will be called.
     */
    pub fn interrupt(&mut self, ram: &mut ram::RAM, i: Interrupt) {
        ram._or(Mem::IF, i.bits());
        self.halt = false; // interrupts interrupt HALT state
    }

    pub fn tick(&mut self, ram: &mut ram::RAM) -> Result<()> {
        self.tick_dma(ram);
        self.tick_clock(ram);
        self.tick_interrupts(ram);
        if self.halt {
            return Ok(());
        }
        if self.stop {
            return Err(anyhow!("CPU Halted"));
        }
        self.tick_instructions(ram);

        return Ok(());
    }

    fn dump_regs(&self, ram: &ram::RAM) {
        let mut op = ram.get(self.pc);
        let op_str = if op == 0xCB {
            op = ram.get(self.pc + 1);
            OP_CB_NAMES[op as usize].to_string()
        } else {
            let base = OP_NAMES[op as usize].to_string();
            let arg = self.load_op(ram, self.pc + 1, OP_TYPES[op as usize]);
            match OP_TYPES[op as usize] {
                0 => base,
                1 => base.replace("n", format!("${:02X}", arg.u8).as_str()),
                2 => base.replace("nn", format!("${:04X}", arg.u16).as_str()),
                3 => base.replace("n", format!("{:+}", arg.i8).as_str()),
                _ => "Invalid arg_type".to_string(),
            }
        };

        let z = if self.flag_z { 'Z' } else { 'z' };
        let n = if self.flag_n { 'N' } else { 'n' };
        let c = if self.flag_c { 'C' } else { 'c' };
        let h = if self.flag_h { 'H' } else { 'h' };

        let ien = Interrupt::from_bits(ram.get(Mem::IE)).unwrap();
        let ifl = Interrupt::from_bits(ram.get(Mem::IF)).unwrap();
        let flag = |i: Interrupt, c: char| -> char {
            if ien.contains(i) {
                if ifl.contains(i) {
                    c.to_ascii_uppercase()
                } else {
                    c
                }
            } else {
                '_'
            }
        };
        let v = flag(Interrupt::VBLANK, 'v');
        let l = flag(Interrupt::STAT, 'l');
        let t = flag(Interrupt::TIMER, 't');
        let s = flag(Interrupt::SERIAL, 's');
        let j = flag(Interrupt::JOYPAD, 'j');

        // printf("A F  B C  D E  H L  : SP   = [SP] : F    : IE/IF : PC   = OP : INSTR\n");
        unsafe {
            println!(
                "{:04X} {:04X} {:04X} {:04X} : {:04X} = {:02X}{:02X} : {}{}{}{} : {}{}{}{}{} : {:04X} = {:02X} : {}",
                self.regs.r16.af,
                self.regs.r16.bc,
                self.regs.r16.de,
                self.regs.r16.hl,
                self.sp, ram.get(self.sp.overflowing_add(1).0), ram.get(self.sp),
                z, n, h, c,
                v, l, t, s, j,
                self.pc, op, op_str
            );
        }
    }

    /**
     * If there is a non-zero value in `ram[Mem::DMA]`, eg 0x42, then
     * we should copy memory from eg 0x4200 to OAM space.
     */
    fn tick_dma(&self, ram: &mut ram::RAM) {
        // TODO: DMA should take 26 cycles, during which main RAM is inaccessible
        if ram.get(Mem::DMA) != 0 {
            let dma_src: u16 = (ram.get(Mem::DMA) as u16) << 8;
            for i in 0..0xA0 {
                ram.set(Mem::OamBase as u16 + i, ram.get(dma_src + i));
            }
            ram.set(Mem::DMA, 0x00);
        }
    }

    /**
     * Increment the timer registers, and send an interrupt
     * when `ram[Mem::TIMA]` wraps around.
     */
    fn tick_clock(&mut self, ram: &mut ram::RAM) {
        self.cycle += 1;

        // TODO: writing any value to Mem::DIV should reset it to 0x00
        // increment at 16384Hz (each 64 cycles?)
        if self.cycle % 64 == 0 {
            ram._inc(Mem::DIV);
        }

        if ram.get(Mem::TAC) & 1 << 2 == 1 << 2 {
            // timer enable
            let speeds: [u32; 4] = [256, 4, 16, 64]; // increment per X cycles
            let speed = speeds[(ram.get(Mem::TAC) & 0x03) as usize];
            if self.cycle % speed == 0 {
                if ram.get(Mem::TIMA) == 0xFF {
                    ram.set(Mem::TIMA, ram.get(Mem::TMA)); // if timer overflows, load base
                    self.interrupt(ram, Interrupt::TIMER);
                }
                ram._inc(Mem::TIMA);
            }
        }
    }

    /**
     * Compare Interrupt Enabled and Interrupt Flag registers - if
     * there are any interrupts which are both enabled and flagged,
     * clear the flag and call the handler for the first of them.
     */
    fn tick_interrupts(&mut self, ram: &mut ram::RAM) {
        let queued_interrupts = Interrupt::from_bits(ram.get(Mem::IE) & ram.get(Mem::IF)).unwrap();
        if self.interrupts && !queued_interrupts.is_empty() {
            if self.debug {
                println!(
                    "Handling interrupts: {:02X} & {:02X}",
                    ram.get(Mem::IE),
                    ram.get(Mem::IF)
                );
            }

            // no nested interrupts, RETI will re-enable
            self.interrupts = false;

            // TODO: wait two cycles
            // TODO: push16(PC) should also take two cycles
            // TODO: one more cycle to store new PC
            if queued_interrupts.contains(Interrupt::VBLANK) {
                self.push(self.pc, ram);
                self.pc = Mem::VBlankHandler as u16;
                ram._and(Mem::IF, !Interrupt::VBLANK.bits());
            } else if queued_interrupts.contains(Interrupt::STAT) {
                self.push(self.pc, ram);
                self.pc = Mem::LcdHandler as u16;
                ram._and(Mem::IF, !Interrupt::STAT.bits());
            } else if queued_interrupts.contains(Interrupt::TIMER) {
                self.push(self.pc, ram);
                self.pc = Mem::TimerHandler as u16;
                ram._and(Mem::IF, !Interrupt::TIMER.bits());
            } else if queued_interrupts.contains(Interrupt::SERIAL) {
                self.push(self.pc, ram);
                self.pc = Mem::SerialHandler as u16;
                ram._and(Mem::IF, !Interrupt::SERIAL.bits());
            } else if queued_interrupts.contains(Interrupt::JOYPAD) {
                self.push(self.pc, ram);
                self.pc = Mem::JoypadHandler as u16;
                ram._and(Mem::IF, !Interrupt::JOYPAD.bits());
            }
        }
    }

    /**
     * Pick an instruction from RAM as pointed to by the
     * Program Counter register; if the instruction takes
     * an argument then pick that too; then execute it.
     */
    fn tick_instructions(&mut self, ram: &mut ram::RAM) {
        // if the previous instruction was large, let's not run any
        // more instructions until other subsystems have caught up
        if self.owed_cycles > 0 {
            self.owed_cycles -= 1;
            return;
        }

        if self.debug {
            self.dump_regs(ram);
        }

        let op = ram.get(self.pc);
        self.pc += 1;
        if op == 0xCB {
            let op = ram.get(self.pc);
            self.pc += 1;
            self.tick_cb(ram, op);
            self.owed_cycles = OP_CB_CYCLES[op as usize];
        } else {
            self.tick_main(ram, op);
            self.owed_cycles = OP_CYCLES[op as usize];
        }

        let mut f = Flag::empty();
        if self.flag_z {
            f.insert(Flag::Z)
        }
        if self.flag_n {
            f.insert(Flag::N)
        }
        if self.flag_h {
            f.insert(Flag::H)
        }
        if self.flag_c {
            f.insert(Flag::C)
        }
        self.regs.r8.f = f.bits();

        // HALT has cycles=0
        if self.owed_cycles > 0 {
            self.owed_cycles -= 1;
        }
    }

    #[inline(always)]
    fn load_op(&self, ram: &ram::RAM, addr: u16, arg_type: u8) -> OpArg {
        match arg_type {
            0 => OpArg {
                u8: 0,
                u16: 0,
                i8: 0,
            },
            1 => OpArg {
                u8: ram.get(addr),
                u16: 0,
                i8: 0,
            },
            2 => OpArg {
                u8: 0,
                u16: (ram.get(addr + 1) as u16) << 8 | (ram.get(addr) as u16),
                i8: 0,
            },
            3 => OpArg {
                u8: 0,
                u16: 0,
                i8: ram.get(addr) as i8,
            },
            n => panic!("Unknown arg type: {}", n),
        }
    }

    fn tick_main(&mut self, ram: &mut ram::RAM, op: u8) {
        let arg = {
            let arg_type = OP_TYPES[op as usize];
            let arg_len = OP_LENS[arg_type as usize];
            let arg = self.load_op(ram, self.pc, arg_type);
            self.pc += arg_len;
            arg
        };

        unsafe {
            match op {
                0x00 => { /* NOP */ }
                0x01 => {
                    self.regs.r16.bc = arg.u16;
                }
                0x02 => {
                    ram.set(self.regs.r16.bc, self.regs.r8.a);
                }
                0x03 => {
                    self.regs.r16.bc = self.regs.r16.bc.overflowing_add(1).0;
                }
                0x08 => {
                    ram.set(arg.u16 + 1, (self.sp >> 8) as u8 & 0xFF);
                    ram.set(arg.u16, self.sp as u8 & 0xFF);
                } // how does self fit?
                0x0A => {
                    self.regs.r8.a = ram.get(self.regs.r16.bc);
                }
                0x0B => {
                    self.regs.r16.bc = self.regs.r16.bc.overflowing_sub(1).0;
                }

                0x10 => {
                    self.stop = true;
                }
                0x11 => {
                    self.regs.r16.de = arg.u16;
                }
                0x12 => {
                    ram.set(self.regs.r16.de, self.regs.r8.a);
                }
                0x13 => {
                    self.regs.r16.de = self.regs.r16.de.overflowing_add(1).0;
                }
                0x18 => {
                    self.pc = self.pc.overflowing_add(arg.i8 as u16).0;
                }
                0x1A => {
                    self.regs.r8.a = ram.get(self.regs.r16.de);
                }
                0x1B => {
                    self.regs.r16.de = self.regs.r16.de.overflowing_sub(1).0;
                }

                0x20 => {
                    if !self.flag_z {
                        self.pc = self.pc.overflowing_add(arg.i8 as u16).0;
                    }
                }
                0x21 => {
                    self.regs.r16.hl = arg.u16;
                }
                0x22 => {
                    ram.set(self.regs.r16.hl, self.regs.r8.a);
                    self.regs.r16.hl = self.regs.r16.hl.overflowing_add(1).0;
                }
                0x23 => {
                    self.regs.r16.hl = self.regs.r16.hl.overflowing_add(1).0;
                }
                0x27 => {
                    let mut val16 = self.regs.r8.a as u16;
                    if !self.flag_n {
                        if self.flag_h || (val16 & 0x0F) > 9 {
                            val16 = val16.overflowing_add(6).0;
                        }
                        if self.flag_c || val16 > 0x9F {
                            val16 = val16.overflowing_add(0x60).0;
                        }
                    } else {
                        if self.flag_h {
                            val16 = val16.overflowing_sub(6).0;
                            if !self.flag_c {
                                val16 &= 0xFF;
                            }
                        }
                        if self.flag_c {
                            val16 = val16.overflowing_sub(0x60).0;
                        }
                    }
                    self.flag_h = false;
                    if val16 & 0x100 != 0 {
                        self.flag_c = true;
                    }
                    self.regs.r8.a = val16 as u8 & 0xFF;
                    self.flag_z = self.regs.r8.a == 0;
                }
                0x28 => {
                    if self.flag_z {
                        self.pc = self.pc.overflowing_add(arg.i8 as u16).0;
                    }
                }
                0x2A => {
                    self.regs.r8.a = ram.get(self.regs.r16.hl);
                    self.regs.r16.hl = self.regs.r16.hl.overflowing_add(1).0;
                }
                0x2B => {
                    self.regs.r16.hl = self.regs.r16.hl.overflowing_sub(1).0;
                }
                0x2F => {
                    self.regs.r8.a ^= 0xFF;
                    self.flag_n = true;
                    self.flag_h = true;
                }

                0x30 => {
                    if !self.flag_c {
                        self.pc = self.pc.overflowing_add(arg.i8 as u16).0;
                    }
                }
                0x31 => {
                    self.sp = arg.u16;
                }
                0x32 => {
                    ram.set(self.regs.r16.hl, self.regs.r8.a);
                    self.regs.r16.hl = self.regs.r16.hl.overflowing_sub(1).0;
                }
                0x33 => {
                    self.sp = self.sp.overflowing_add(1).0;
                }
                0x37 => {
                    self.flag_n = false;
                    self.flag_h = false;
                    self.flag_c = true;
                }
                0x38 => {
                    if self.flag_c {
                        self.pc = self.pc.overflowing_add(arg.i8 as u16).0;
                    }
                }
                0x3A => {
                    self.regs.r8.a = ram.get(self.regs.r16.hl);
                    self.regs.r16.hl = self.regs.r16.hl.overflowing_sub(1).0;
                }
                0x3B => {
                    self.sp = self.sp.overflowing_sub(1).0;
                }
                0x3F => {
                    self.flag_c = !self.flag_c;
                    self.flag_n = false;
                    self.flag_h = false;
                }

                // INC r
                0x04 | 0x0C | 0x14 | 0x1C | 0x24 | 0x2C | 0x34 | 0x3C => {
                    let val = self.get_reg((op - 0x04) / 8, ram);
                    self.flag_h = (val & 0x0F) == 0x0F;
                    self.flag_z = val.overflowing_add(1).0 == 0;
                    self.flag_n = false;
                    self.set_reg((op - 0x04) / 8, val.overflowing_add(1).0, ram);
                }

                // DEC r
                0x05 | 0x0D | 0x15 | 0x1D | 0x25 | 0x2D | 0x35 | 0x3D => {
                    let val = self.get_reg((op - 0x05) / 8, ram);
                    self.flag_h = (val.overflowing_sub(1).0 & 0x0F) == 0x0F;
                    self.flag_z = val.overflowing_sub(1).0 == 0;
                    self.flag_n = true;
                    self.set_reg((op - 0x05) / 8, val.overflowing_sub(1).0, ram);
                }

                // LD r,n
                0x06 | 0x0E | 0x16 | 0x1E | 0x26 | 0x2E | 0x36 | 0x3E => {
                    self.set_reg((op - 0x06) / 8, arg.u8, ram);
                }

                // RCLA, RLA, RRCA, RRA
                0x07 | 0x17 | 0x0F | 0x1F => {
                    let carry = if self.flag_c { 1 } else { 0 };
                    if op == 0x07 {
                        // RCLA
                        self.flag_c = (self.regs.r8.a & 1 << 7) != 0;
                        self.regs.r8.a = (self.regs.r8.a << 1) | (self.regs.r8.a >> 7);
                    }
                    if op == 0x17 {
                        // RLA
                        self.flag_c = (self.regs.r8.a & 1 << 7) != 0;
                        self.regs.r8.a = (self.regs.r8.a << 1) | carry;
                    }
                    if op == 0x0F {
                        // RRCA
                        self.flag_c = (self.regs.r8.a & 1 << 0) != 0;
                        self.regs.r8.a = (self.regs.r8.a >> 1) | (self.regs.r8.a << 7);
                    }
                    if op == 0x1F {
                        // RRA
                        self.flag_c = (self.regs.r8.a & 1 << 0) != 0;
                        self.regs.r8.a = (self.regs.r8.a >> 1) | (carry << 7);
                    }
                    self.flag_n = false;
                    self.flag_h = false;
                    self.flag_z = false;
                }

                // ADD HL,rr
                0x09 | 0x19 | 0x29 | 0x39 => {
                    let val16 = match op {
                        0x09 => self.regs.r16.bc,
                        0x19 => self.regs.r16.de,
                        0x29 => self.regs.r16.hl,
                        0x39 => self.sp,
                        _ => 0,
                    };
                    self.flag_h = (self.regs.r16.hl & 0x0FFF) + (val16 & 0x0FFF) > 0x0FFF;
                    self.flag_c = (self.regs.r16.hl as u32 + val16 as u32) > 0xFFFF;
                    self.regs.r16.hl = self.regs.r16.hl.overflowing_add(val16).0;
                    self.flag_n = false;
                }

                0x40..=0x7F => {
                    // LD r,r
                    if op == 0x76 {
                        // FIXME: weird timing side effects
                        self.halt = true;
                    }
                    self.set_reg((op - 0x40) / 8, self.get_reg((op - 0x40) % 8, ram), ram);
                }

                // <math> <reg>
                0x80..=0x87 => self._add(self.get_reg(op, ram)),
                0x88..=0x8F => self._adc(self.get_reg(op, ram)),
                0x90..=0x97 => self._sub(self.get_reg(op, ram)),
                0x98..=0x9F => self._sbc(self.get_reg(op, ram)),
                0xA0..=0xA7 => self._and(self.get_reg(op, ram)),
                0xA8..=0xAF => self._xor(self.get_reg(op, ram)),
                0xB0..=0xB7 => self._or(self.get_reg(op, ram)),
                0xB8..=0xBF => self._cp(self.get_reg(op, ram)),

                0xC0 => {
                    if !self.flag_z {
                        self.pc = self.pop(ram);
                    }
                }
                0xC1 => {
                    self.regs.r16.bc = self.pop(ram);
                }
                0xC2 => {
                    if !self.flag_z {
                        self.pc = arg.u16;
                    }
                }
                0xC3 => {
                    self.pc = arg.u16;
                }
                0xC4 => {
                    if !self.flag_z {
                        self.push(self.pc, ram);
                        self.pc = arg.u16;
                    }
                }
                0xC5 => {
                    self.push(self.regs.r16.bc, ram);
                }
                0xC6 => {
                    self._add(arg.u8);
                }
                0xC7 => {
                    self.push(self.pc, ram);
                    self.pc = 0x00;
                }
                0xC8 => {
                    if self.flag_z {
                        self.pc = self.pop(ram);
                    }
                }
                0xC9 => {
                    self.pc = self.pop(ram);
                }
                0xCA => {
                    if self.flag_z {
                        self.pc = arg.u16;
                    }
                }
                0xCC => {
                    if self.flag_z {
                        self.push(self.pc, ram);
                        self.pc = arg.u16;
                    }
                }
                0xCD => {
                    self.push(self.pc, ram);
                    self.pc = arg.u16;
                }
                0xCE => {
                    self._adc(arg.u8);
                }
                0xCF => {
                    self.push(self.pc, ram);
                    self.pc = 0x08;
                }

                0xD0 => {
                    if !self.flag_c {
                        self.pc = self.pop(ram);
                    }
                }
                0xD1 => {
                    self.regs.r16.de = self.pop(ram);
                }
                0xD2 => {
                    if !self.flag_c {
                        self.pc = arg.u16;
                    }
                }
                0xD4 => {
                    if !self.flag_c {
                        self.push(self.pc, ram);
                        self.pc = arg.u16;
                    }
                }
                0xD5 => {
                    self.push(self.regs.r16.de, ram);
                }
                0xD6 => {
                    self._sub(arg.u8);
                }
                0xD7 => {
                    self.push(self.pc, ram);
                    self.pc = 0x10;
                }
                0xD8 => {
                    if self.flag_c {
                        self.pc = self.pop(ram);
                    }
                }
                0xD9 => {
                    self.pc = self.pop(ram);
                    self.interrupts = true;
                }
                0xDA => {
                    if self.flag_c {
                        self.pc = arg.u16;
                    }
                }
                0xDC => {
                    if self.flag_c {
                        self.push(self.pc, ram);
                        self.pc = arg.u16;
                    }
                }
                0xDE => {
                    self._sbc(arg.u8);
                }
                0xDF => {
                    self.push(self.pc, ram);
                    self.pc = 0x18;
                }

                0xE0 => {
                    ram.set(0xFF00 + arg.u8 as u16, self.regs.r8.a);
                    if arg.u8 == 0x01 {
                        print!("{}", self.regs.r8.a as char);
                    };
                }
                0xE1 => {
                    self.regs.r16.hl = self.pop(ram);
                }
                0xE2 => {
                    ram.set(0xFF00 + self.regs.r8.c as u16, self.regs.r8.a);
                    if self.regs.r8.c == 0x01 {
                        print!("{}", self.regs.r8.a as char);
                    };
                }
                //0xE3 => self._err(op),
                //0xE4 => self._err(op),
                0xE5 => {
                    self.push(self.regs.r16.hl, ram);
                }
                0xE6 => {
                    self._and(arg.u8);
                }
                0xE7 => {
                    self.push(self.pc, ram);
                    self.pc = 0x20;
                }
                0xE8 => {
                    let val16 = self.sp.overflowing_add(arg.i8 as u16).0;
                    //self.flag_h = ((self.sp & 0x0FFF) + (arg.i8 & 0x0FFF) > 0x0FFF);
                    //self.flag_c = (self.sp + arg.i8 > 0xFFFF);
                    self.flag_h = ((self.sp ^ arg.i8 as u16 ^ val16) & 0x10) != 0;
                    self.flag_c = ((self.sp ^ arg.i8 as u16 ^ val16) & 0x100) != 0;
                    if arg.i8 > 0 {
                        self.sp = self.sp.overflowing_add(arg.i8 as u16).0;
                    } else {
                        self.sp = self.sp.overflowing_sub((-arg.i8) as u16).0;
                    }
                    self.flag_z = false;
                    self.flag_n = false;
                }
                0xE9 => {
                    self.pc = self.regs.r16.hl;
                }
                0xEA => {
                    ram.set(arg.u16, self.regs.r8.a);
                }
                0xEE => {
                    self._xor(arg.u8);
                }
                0xEF => {
                    self.push(self.pc, ram);
                    self.pc = 0x28;
                }

                0xF0 => {
                    self.regs.r8.a = ram.get(0xFF00 + arg.u8 as u16);
                }
                0xF1 => {
                    self.regs.r16.af = self.pop(ram) & 0xFFF0;
                    let f = Flag::from_bits(self.regs.r8.f).unwrap();
                    self.flag_z = f.contains(Flag::Z);
                    self.flag_n = f.contains(Flag::N);
                    self.flag_h = f.contains(Flag::H);
                    self.flag_c = f.contains(Flag::C);
                }
                0xF2 => {
                    self.regs.r8.a = ram.get(0xFF00 + self.regs.r8.c as u16);
                }
                0xF3 => {
                    self.interrupts = false;
                }
                0xF5 => {
                    self.push(self.regs.r16.af, ram);
                }
                0xF6 => self._or(arg.u8),
                0xF7 => {
                    self.push(self.pc, ram);
                    self.pc = 0x30;
                }
                0xF8 => {
                    let new_hl = self.sp.overflowing_add(arg.i8 as u16).0;
                    if arg.i8 >= 0 {
                        self.flag_c = ((self.sp & 0xFF) + (arg.i8) as u16) > 0xFF;
                        self.flag_h = ((self.sp & 0x0F) + (arg.i8 & 0x0F) as u16) > 0x0F;
                    } else {
                        self.flag_c = (new_hl & 0xFF) <= (self.sp & 0xFF);
                        self.flag_h = (new_hl & 0x0F) <= (self.sp & 0x0F);
                    }
                    self.regs.r16.hl = new_hl;
                    self.flag_z = false;
                    self.flag_n = false;
                }
                0xF9 => self.sp = self.regs.r16.hl,
                0xFA => self.regs.r8.a = ram.get(arg.u16),
                0xFB => self.interrupts = true,
                0xFE => self._cp(arg.u8),
                0xFF => {
                    self.push(self.pc, ram);
                    self.pc = 0x38;
                }
                _ => panic!("Unimplemented opcode: {:02X}", op),
            }
        }
    }

    /**
     * CB instructions all share a format where the first
     * 5 bits of the opcode defines the instruction, and
     * the latter 3 bits of the opcode define the data to
     * work with (7 registers + 1 "RAM at HL").
     *
     * We can take advantage of this to avoid copy-pasting,
     * by loading the data based on the 3 bits, executing
     * an instruction based on the 5, and then storing the
     * data based on the 3 again.
     */
    fn tick_cb(&mut self, ram: &mut ram::RAM, op: u8) {
        let mut val = self.get_reg(op & 0x07, ram);
        match op & 0xF8 {
            // RLC
            0x00..=0x07 => {
                self.flag_c = (val & 1 << 7) != 0;
                val <<= 1;
                if self.flag_c {
                    val |= 1 << 0;
                }
                self.flag_n = false;
                self.flag_h = false;
                self.flag_z = val == 0;
            }

            // RRC
            0x08..=0x0F => {
                self.flag_c = (val & 1 << 0) != 0;
                val >>= 1;
                if self.flag_c {
                    val |= 1 << 7;
                }
                self.flag_n = false;
                self.flag_h = false;
                self.flag_z = val == 0;
            }

            // RL
            0x10..=0x17 => {
                let orig_c = self.flag_c;
                self.flag_c = (val & 1 << 7) != 0;
                val <<= 1;
                if orig_c {
                    val |= 1 << 0;
                }
                self.flag_n = false;
                self.flag_h = false;
                self.flag_z = val == 0;
            }

            // RR
            0x18..=0x1F => {
                let orig_c = self.flag_c;
                self.flag_c = (val & 1 << 0) != 0;
                val >>= 1;
                if orig_c {
                    val |= 1 << 7;
                }
                self.flag_n = false;
                self.flag_h = false;
                self.flag_z = val == 0;
            }

            // SLA
            0x20..=0x27 => {
                self.flag_c = (val & 1 << 7) != 0;
                val <<= 1;
                val &= 0xFF;
                self.flag_n = false;
                self.flag_h = false;
                self.flag_z = val == 0;
            }

            // SRA
            0x28..=0x2F => {
                self.flag_c = (val & 1 << 0) != 0;
                val >>= 1;
                if val & 1 << 6 != 0 {
                    val |= 1 << 7;
                }
                self.flag_n = false;
                self.flag_h = false;
                self.flag_z = val == 0;
            }

            // SWAP
            0x30..=0x37 => {
                val = ((val & 0xF0) >> 4) | ((val & 0x0F) << 4);
                self.flag_c = false;
                self.flag_n = false;
                self.flag_h = false;
                self.flag_z = val == 0;
            }

            // SRL
            0x38..=0x3F => {
                self.flag_c = (val & 1 << 0) != 0;
                val >>= 1;
                self.flag_n = false;
                self.flag_h = false;
                self.flag_z = val == 0;
            }

            // BIT
            0x40..=0x7F => {
                let bit = (op - 0x40) / 8;
                self.flag_z = (val & (1 << bit)) == 0;
                self.flag_n = false;
                self.flag_h = true;
            }

            // SET
            0x80..=0xBF => {
                let bit = (op - 0x80) / 8;
                val &= (1 << bit) ^ 0xFF;
            }

            // RES
            0xC0..=0xFF => {
                let bit = (op - 0xC0) / 8;
                val |= 1 << bit;
            }
        }
        self.set_reg(op & 0x07, val, ram);
    }

    fn _xor(&mut self, val: u8) {
        unsafe {
            self.regs.r8.a ^= val;

            self.flag_z = self.regs.r8.a == 0;
            self.flag_n = false;
            self.flag_h = false;
            self.flag_c = false;
        }
    }

    fn _or(&mut self, val: u8) {
        unsafe {
            self.regs.r8.a |= val;

            self.flag_z = self.regs.r8.a == 0;
            self.flag_n = false;
            self.flag_h = false;
            self.flag_c = false;
        }
    }

    fn _and(&mut self, val: u8) {
        unsafe {
            self.regs.r8.a &= val;

            self.flag_z = self.regs.r8.a == 0;
            self.flag_n = false;
            self.flag_h = true;
            self.flag_c = false;
        }
    }

    fn _cp(&mut self, val: u8) {
        unsafe {
            self.flag_z = self.regs.r8.a == val;
            self.flag_n = true;
            self.flag_h = (self.regs.r8.a & 0x0F) < (val & 0x0F);
            self.flag_c = self.regs.r8.a < val;
        }
    }

    fn _add(&mut self, val: u8) {
        unsafe {
            self.flag_c = self.regs.r8.a as u16 + val as u16 > 0xFF;
            self.flag_h = (self.regs.r8.a & 0x0F) + (val & 0x0F) > 0x0F;
            self.flag_n = false;
            self.regs.r8.a = self.regs.r8.a.overflowing_add(val).0;
            self.flag_z = self.regs.r8.a == 0;
        }
    }

    fn _adc(&mut self, val: u8) {
        unsafe {
            let carry: u8 = if self.flag_c { 1 } else { 0 };
            self.flag_c = (self.regs.r8.a as u16 + val as u16 + carry as u16 > 0xFF) as bool;
            self.flag_h = (self.regs.r8.a & 0x0F) + (val & 0x0F) + carry > 0x0F;
            self.flag_n = false;
            self.regs.r8.a = self
                .regs
                .r8
                .a
                .overflowing_add(val)
                .0
                .overflowing_add(carry)
                .0;
            self.flag_z = self.regs.r8.a == 0;
        }
    }

    fn _sub(&mut self, val: u8) {
        unsafe {
            self.flag_c = self.regs.r8.a < val;
            self.flag_h = (self.regs.r8.a & 0x0F) < (val & 0x0F);
            self.regs.r8.a = self.regs.r8.a.overflowing_sub(val).0;
            self.flag_z = self.regs.r8.a == 0;
            self.flag_n = true;
        }
    }

    fn _sbc(&mut self, val: u8) {
        unsafe {
            let carry: u8 = if self.flag_c { 1 } else { 0 };
            let res = self.regs.r8.a as i32 - val as i32 - carry as i32;
            self.flag_h = ((self.regs.r8.a ^ val ^ (res as u8 & 0xff)) & (1 << 4)) != 0;
            self.flag_c = res < 0;
            self.regs.r8.a = self
                .regs
                .r8
                .a
                .overflowing_sub(val)
                .0
                .overflowing_sub(carry)
                .0;
            self.flag_z = self.regs.r8.a == 0;
            self.flag_n = true;
        }
    }

    fn push(&mut self, val: u16, ram: &mut ram::RAM) {
        ram.set(self.sp - 1, (((val & 0xFF00) >> 8) & 0xFF) as u8);
        ram.set(self.sp - 2, (val & 0xFF) as u8);
        self.sp -= 2;
    }

    fn pop(&mut self, ram: &ram::RAM) -> u16 {
        let val = ((ram.get(self.sp + 1) as u16) << 8) | ram.get(self.sp) as u16;
        self.sp += 2;
        return val;
    }
}
