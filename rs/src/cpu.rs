use crate::consts;
use crate::ram;

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
    pub fn interrupt(&mut self, ram: &mut ram::RAM, i: consts::Interrupt) {
        ram._or(consts::IO::IF, i.bits());
        self.halt = false; // interrupts interrupt HALT state
    }

    pub fn tick(&mut self, ram: &mut ram::RAM) -> Result<(), String> {
        self.tick_dma(ram);
        self.tick_clock(ram);
        self.tick_interrupts(ram);
        if self.halt {
            return Ok(());
        }
        if self.stop {
            return Err("CPU Halted".to_string());
        }
        self.tick_instructions(ram);

        return Ok(());
    }

    fn dump_regs(&self, ram: &ram::RAM) {
        let mut op = ram.get(self.pc);
        let op_str = if op == 0xCB {
            op = ram.get(self.pc + 1);
            consts::OP_CB_NAMES[op as usize].to_string()
        } else {
            let base = consts::OP_NAMES[op as usize].to_string();
            let arg = self.load_op(ram, self.pc + 1, consts::OP_TYPES[op as usize]);
            match consts::OP_TYPES[op as usize] {
                0 => base.to_string(),
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

        let ien = consts::Interrupt::from_bits(ram.get(consts::IO::IE)).unwrap();
        let ifl = consts::Interrupt::from_bits(ram.get(consts::IO::IF)).unwrap();
        let flag = |i: consts::Interrupt, c: char| -> char {
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
        let v = flag(consts::Interrupt::VBLANK, 'v');
        let l = flag(consts::Interrupt::STAT, 'l');
        let t = flag(consts::Interrupt::TIMER, 't');
        let s = flag(consts::Interrupt::SERIAL, 's');
        let j = flag(consts::Interrupt::JOYPAD, 'j');

        // printf("A F  B C  D E  H L  : SP   = [SP] : F    : IE/IF : PC   = OP : INSTR\n");
        unsafe {
            println!(
                "{:04X} {:04X} {:04X} {:04X} : {:04X} = {:04X} : {}{}{}{} : {}{}{}{}{} : {:04X} = {:02X} : {}",
                self.regs.r16.af,
                self.regs.r16.bc,
                self.regs.r16.de,
                self.regs.r16.hl,
                self.sp,
                (ram.get(self.sp.overflowing_add(1).0) as u16) << 8 & ram.get(self.sp) as u16,
                z, n, h, c,
                v, l, t, s, j,
                self.pc, op, op_str
            );
        }
    }

    /**
     * If there is a non-zero value in `ram[IO::DMA]`, eg 0x42, then
     * we should copy memory from eg 0x4200 to OAM space.
     */
    fn tick_dma(&self, ram: &mut ram::RAM) {
        // TODO: DMA should take 26 cycles, during which main RAM is inaccessible
        if ram.get(consts::IO::DMA) != 0 {
            let dma_src: u16 = (ram.get(consts::IO::DMA) as u16) << 8;
            for i in 0..0xA0 {
                ram.set(consts::Mem::OamBase as u16 + i, ram.get(dma_src + i));
            }
            ram.set(consts::IO::DMA, 0x00);
        }
    }

    /**
     * Increment the timer registers, and send an interrupt
     * when `ram[IO::TIMA]` wraps around.
     */
    fn tick_clock(&mut self, ram: &mut ram::RAM) {
        self.cycle += 1;

        // TODO: writing any value to IO::DIV should reset it to 0x00
        // increment at 16384Hz (each 64 cycles?)
        if self.cycle % 64 == 0 {
            ram._inc(consts::IO::DIV);
        }

        if ram.get(consts::IO::TAC) & 1 << 2 == 1 << 2 {
            // timer enable
            let speeds: [u32; 4] = [256, 4, 16, 64]; // increment per X cycles
            let speed = speeds[(ram.get(consts::IO::TAC) & 0x03) as usize];
            if self.cycle % speed == 0 {
                if ram.get(consts::IO::TIMA) == 0xFF {
                    ram.set(consts::IO::TIMA, ram.get(consts::IO::TMA)); // if timer overflows, load base
                    self.interrupt(ram, consts::Interrupt::TIMER);
                }
                ram._inc(consts::IO::TIMA);
            }
        }
    }

    /**
     * Compare Interrupt Enabled and Interrupt Flag registers - if
     * there are any interrupts which are both enabled and flagged,
     * clear the flag and call the handler for the first of them.
     */
    fn tick_interrupts(&mut self, ram: &mut ram::RAM) {
        let queued_interrupts =
            consts::Interrupt::from_bits(ram.get(consts::IO::IE) & ram.get(consts::IO::IF))
                .unwrap();
        if self.interrupts && !queued_interrupts.is_empty() {
            if self.debug {
                println!(
                    "Handling interrupts: {:02X} & {:02X}",
                    ram.get(consts::IO::IE),
                    ram.get(consts::IO::IF)
                );
            }

            // no nested interrupts, RETI will re-enable
            self.interrupts = false;

            // TODO: wait two cycles
            // TODO: push16(PC) should also take two cycles
            // TODO: one more cycle to store new PC
            if queued_interrupts.contains(consts::Interrupt::VBLANK) {
                self.push(self.pc, ram);
                self.pc = consts::InterruptHandler::VblankHandler as u16;
                ram._and(consts::IO::IF, !consts::Interrupt::VBLANK.bits());
            } else if queued_interrupts.contains(consts::Interrupt::STAT) {
                self.push(self.pc, ram);
                self.pc = consts::InterruptHandler::LcdHandler as u16;
                ram._and(consts::IO::IF, !consts::Interrupt::STAT.bits());
            } else if queued_interrupts.contains(consts::Interrupt::TIMER) {
                self.push(self.pc, ram);
                self.pc = consts::InterruptHandler::TimerHandler as u16;
                ram._and(consts::IO::IF, !consts::Interrupt::TIMER.bits());
            } else if queued_interrupts.contains(consts::Interrupt::SERIAL) {
                self.push(self.pc, ram);
                self.pc = consts::InterruptHandler::SerialHandler as u16;
                ram._and(consts::IO::IF, !consts::Interrupt::SERIAL.bits());
            } else if queued_interrupts.contains(consts::Interrupt::JOYPAD) {
                self.push(self.pc, ram);
                self.pc = consts::InterruptHandler::JoypadHandler as u16;
                ram._and(consts::IO::IF, !consts::Interrupt::JOYPAD.bits());
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
            self.owed_cycles = consts::OP_CB_CYCLES[op as usize];
        } else {
            self.tick_main(ram, op);
            self.owed_cycles = consts::OP_CYCLES[op as usize];
        }

        let mut f = consts::Flag::empty();
        if self.flag_z {
            f.insert(consts::Flag::Z)
        }
        if self.flag_n {
            f.insert(consts::Flag::N)
        }
        if self.flag_h {
            f.insert(consts::Flag::H)
        }
        if self.flag_c {
            f.insert(consts::Flag::C)
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
            let arg_type = consts::OP_TYPES[op as usize];
            let arg_len = consts::OP_LENS[arg_type as usize];
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
                    let f = consts::Flag::from_bits(self.regs.r8.f).unwrap();
                    self.flag_z = f.contains(consts::Flag::Z);
                    self.flag_n = f.contains(consts::Flag::N);
                    self.flag_h = f.contains(consts::Flag::H);
                    self.flag_c = f.contains(consts::Flag::C);
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

    fn _xor(&mut self, arg: u8) {
        unsafe {
            self.regs.r8.a ^= arg;

            self.flag_z = self.regs.r8.a == 0;
            self.flag_n = false;
            self.flag_h = false;
            self.flag_c = false;
        }
    }

    fn _or(&mut self, arg: u8) {
        unsafe {
            self.regs.r8.a |= arg;

            self.flag_z = self.regs.r8.a == 0;
            self.flag_n = false;
            self.flag_h = false;
            self.flag_c = false;
        }
    }

    fn _and(&mut self, arg: u8) {
        unsafe {
            self.regs.r8.a &= arg;

            self.flag_z = self.regs.r8.a == 0;
            self.flag_n = false;
            self.flag_h = true;
            self.flag_c = false;
        }
    }

    fn _cp(&mut self, arg: u8) {
        unsafe {
            self.flag_z = self.regs.r8.a == arg;
            self.flag_n = true;
            self.flag_h = (self.regs.r8.a & 0x0F) < (arg & 0x0F);
            self.flag_c = self.regs.r8.a < arg;
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
