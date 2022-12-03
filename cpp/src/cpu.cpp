#include <cstdio>

#include "consts.h"
#include "cpu.h"
#include "errors.h"

/**
 * Initialise registers and RAM, map the first banks of Cart
 * code into the RAM address space.
 */
CPU::CPU(RAM *ram, bool debug) {
    this->ram = ram;
    this->debug = debug;
    this->interrupts = false;

    this->AF = 0x0000;
    this->BC = 0x0000;
    this->DE = 0x0000;
    this->HL = 0x0000;
    this->SP = 0x0000;
    this->PC = 0x0000;
}

void CPU::dump_regs() {
    // stack
    u16 sp_val = this->ram->get(this->SP) | this->ram->get(this->SP + 1) << 8;

    // interrupts
    u8 IE = this->ram->get(Mem::IE);
    u8 IF = this->ram->get(Mem::IF);
    char z = 'z' ^ ((this->F >> 7) & 1) << 5;
    char n = 'n' ^ ((this->F >> 6) & 1) << 5;
    char h = 'h' ^ ((this->F >> 5) & 1) << 5;
    char c = 'c' ^ ((this->F >> 4) & 1) << 5;
    char v = (IE >> 0) & 1 ? 'v' ^ ((IF >> 0) & 1) << 5 : '_';
    char l = (IE >> 1) & 1 ? 'l' ^ ((IF >> 1) & 1) << 5 : '_';
    char t = (IE >> 2) & 1 ? 't' ^ ((IF >> 2) & 1) << 5 : '_';
    char s = (IE >> 3) & 1 ? 's' ^ ((IF >> 3) & 1) << 5 : '_';
    char j = (IE >> 4) & 1 ? 'j' ^ ((IF >> 4) & 1) << 5 : '_';

    // opcode & args
    u8 op = this->ram->get(PC);
    char op_str[16] = "";
    if(op == 0xCB) {
        op = this->ram->get(PC + 1);
        snprintf(op_str, 16, "%s", CB_OP_NAMES[op].c_str());
    } else {
        if(OP_ARG_TYPES[op] == 0) snprintf(op_str, 16, "%s", OP_NAMES[op].c_str());
        if(OP_ARG_TYPES[op] == 1) snprintf(op_str, 16, OP_NAMES[op].c_str(), this->ram->get(PC + 1));
        if(OP_ARG_TYPES[op] == 2)
            snprintf(op_str, 16, OP_NAMES[op].c_str(), this->ram->get(PC + 1) | this->ram->get(PC + 2) << 8);
        if(OP_ARG_TYPES[op] == 3) snprintf(op_str, 16, OP_NAMES[op].c_str(), (i8)this->ram->get(PC + 1));
    }

    // print
    // clang-format off
    printf(
        "%04X %04X %04X %04X : %04X = %04X : %c%c%c%c : %c%c%c%c%c : %04X = %02X : %s\n",
        AF, BC, DE, HL,
        SP, sp_val,
        z, n, h, c,
        v, l, t, s, j,
        PC, op, op_str
    );
    // clang-format on
}

/**
 * Set a given interrupt bit - on the next tick, if the interrupt
 * handler for this interrupt is enabled (and interrupts in general
 * are enabled), then the interrupt handler will be called.
 */
void CPU::interrupt(Interrupt::Interrupt i) {
    this->ram->set(Mem::IF, this->ram->get(Mem::IF) | i);
    this->halt = false; // interrupts interrupt HALT state
}

void CPU::tick() {
    this->tick_dma();
    this->tick_clock();
    this->tick_interrupts();
    if(this->halt) return;
    if(this->stop) return;
    this->tick_instructions();
}

/**
 * If there is a non-zero value in ram[Mem::DMA], eg 0x42, then
 * we should copy memory from eg 0x4200 to OAM space.
 */
void CPU::tick_dma() {
    // TODO: DMA should take 26 cycles, during which main RAM is inaccessible
    if(this->ram->get(Mem::DMA)) {
        u16 dma_src = this->ram->get(Mem::DMA) << 8;
        for(int i = 0; i < 0xA0; i++) {
            this->ram->set(Mem::OAM_BASE + i, this->ram->get(dma_src + i));
        }
        this->ram->set(Mem::DMA, 0x00);
    }
}

/**
 * Increment the timer registers, and send an interrupt
 * when TIMA wraps around.
 */
void CPU::tick_clock() {
    cycle++;

    // TODO: writing any value to Mem::DIV should reset it to 0x00
    // increment at 16384Hz (each 64 cycles?)
    if(cycle % 64 == 0) this->ram->set(Mem::DIV, this->ram->get(Mem::DIV) + 1);

    if(this->ram->get(Mem::TAC) & (1 << 2)) { // timer enable
        u16 speeds[] = {256, 4, 16, 64};      // increment per X cycles
        u16 speed = speeds[this->ram->get(Mem::TAC) & 0x03];
        if(cycle % speed == 0) {
            if(this->ram->get(Mem::TIMA) == 0xFF) {
                this->ram->set(Mem::TIMA, this->ram->get(Mem::TMA)); // if timer overflows, load base
                this->interrupt(Interrupt::TIMER);
            }
            this->ram->set(Mem::TIMA, this->ram->get(Mem::TIMA) + 1);
        }
    }
}

bool CPU::check_interrupt(u8 queue, u8 i, u16 handler) {
    if(queue & i) {
        // TODO: wait two cycles
        // TODO: push16(PC) should also take two cycles
        // TODO: one more cycle to store new PC
        this->push(this->PC);
        this->PC = handler;
        this->ram->set(Mem::IF, this->ram->get(Mem::IF) & ~i);
        return true;
    }
    return false;
}

/**
 * Compare Interrupt Enabled and Interrupt Flag registers - if
 * there are any interrupts which are both enabled and flagged,
 * clear the flag and call the handler for the first of them.
 */
void CPU::tick_interrupts() {
    u8 queue = this->ram->get(Mem::IE) & this->ram->get(Mem::IF);
    if(this->interrupts && queue) {
        if(debug) printf("Handling interrupts: %02X & %02X\n", this->ram->get(Mem::IE), this->ram->get(Mem::IF));
        this->interrupts = false; // no nested interrupts, RETI will re-enable
        this->check_interrupt(queue, Interrupt::VBLANK, Mem::VBLANK_HANDLER) ||
            this->check_interrupt(queue, Interrupt::STAT, Mem::LCD_HANDLER) ||
            this->check_interrupt(queue, Interrupt::TIMER, Mem::TIMER_HANDLER) ||
            this->check_interrupt(queue, Interrupt::SERIAL, Mem::SERIAL_HANDLER) ||
            this->check_interrupt(queue, Interrupt::JOYPAD, Mem::JOYPAD_HANDLER);
    }
}

/**
 * Pick an instruction from RAM as pointed to by the
 * Program Counter register; if the instruction takes
 * an argument then pick that too; then execute it.
 */
void CPU::tick_instructions() {
    // if the previous instruction was large, let's not run any
    // more instructions until other subsystems have caught up
    if(owed_cycles) {
        owed_cycles--;
        return;
    }

    if(this->debug) {
        this->dump_regs();
    }

    u8 op = this->ram->get(this->PC);
    if(op == 0xCB) {
        op = this->ram->get(this->PC + 1);
        this->PC += 2;
        this->tick_cb(op);
        owed_cycles = OP_CB_CYCLES[op];
    } else {
        oparg arg;
        arg.as_u16 = 0xCA75;
        u8 arg_len = OP_ARG_BYTES[OP_ARG_TYPES[op]];
        if(arg_len == 1) {
            arg.as_u8 = this->ram->get(this->PC + 1);
        }
        if(arg_len == 2) {
            u16 low = this->ram->get(this->PC + 1);
            u16 high = this->ram->get(this->PC + 2);
            arg.as_u16 = high << 8 | low;
        }
        this->PC += 1 + arg_len;
        this->tick_main(op, arg);
        owed_cycles = OP_CYCLES[op];
    }
    if(owed_cycles > 0) owed_cycles -= 1; // HALT has cycles=0
}

/**
 * Execute a normal instruction (everything except for those
 * prefixed with 0xCB)
 */
void CPU::tick_main(u8 op, oparg arg) {
    // Load args

    // Execute
    u8 val = 0, carry = 0;
    u16 val16 = 0;
    switch(op) {
        // clang-format off
        case 0x00: /* NOP */; break;
        case 0x01: this->BC = arg.as_u16; break;
        case 0x02: this->ram->set(this->BC, this->A); break;
        case 0x03: this->BC++; break;
        case 0x08:
            this->ram->set(arg.as_u16+1, ((this->SP >> 8) & 0xFF));
            this->ram->set(arg.as_u16, (this->SP & 0xFF));
            break;  // how does this fit?
        case 0x0A: this->A = this->ram->get(this->BC); break;
        case 0x0B: this->BC--; break;

        case 0x10: this->stop = true; break;
        case 0x11: this->DE = arg.as_u16; break;
        case 0x12: this->ram->set(this->DE, this->A); break;
        case 0x13: this->DE++; break;
        case 0x18: this->PC += arg.as_i8; break;
        case 0x1A: this->A = this->ram->get(this->DE); break;
        case 0x1B: this->DE--; break;

        case 0x20: if(!this->FLAG_Z) this->PC += arg.as_i8; break;
        case 0x21: this->HL = arg.as_u16; break;
        case 0x22: this->ram->set(this->HL++, this->A); break;
        case 0x23: this->HL++; break;
        case 0x27:
            val16 = this->A;
            if(this->FLAG_N == 0) {
                if (this->FLAG_H || (val16 & 0x0F) > 9) val16 += 6;
                if (this->FLAG_C || val16 > 0x9F) val16 += 0x60;
            }
            else {
                if(this->FLAG_H) {
                    val16 -= 6;
                    if (this->FLAG_C == 0) val16 &= 0xFF;
                }
                if(this->FLAG_C) val16 -= 0x60;
            }
            this->FLAG_H = false;
            if(val16 & 0x100) this->FLAG_C = true;
            this->A = val16 & 0xFF;
            this->FLAG_Z = this->A == 0;
            break;
        case 0x28: if(this->FLAG_Z) this->PC += arg.as_i8; break;
        case 0x2A: this->A = this->ram->get(this->HL++); break;
        case 0x2B: this->HL--; break;
        case 0x2F: this->A ^= 0xFF; this->FLAG_N = true; this->FLAG_H = true; break;

        case 0x30: if(!this->FLAG_C) this->PC += arg.as_i8; break;
        case 0x31: this->SP = arg.as_u16; break;
        case 0x32: this->ram->set(this->HL--, this->A); break;
        case 0x33: this->SP++; break;
        case 0x37: this->FLAG_N = false; this->FLAG_H = false; this->FLAG_C = true; break;
        case 0x38: if(this->FLAG_C) this->PC += arg.as_i8; break;
        case 0x3A: this->A = this->ram->get(this->HL--); break;
        case 0x3B: this->SP--; break;
        case 0x3F: this->FLAG_C = !this->FLAG_C; this->FLAG_N = false; this->FLAG_H = false; break;

        case 0x04: case 0x0C: // INC r
        case 0x14: case 0x1C:
        case 0x24: case 0x2C:
        case 0x34: case 0x3C:
            val = this->get_reg((op-0x04)/8);
            this->FLAG_H = (val & 0x0F) == 0x0F;
            val++;
            this->FLAG_Z = val == 0;
            this->FLAG_N = false;
            this->set_reg((op-0x04)/8, val);
            break;

        case 0x05: case 0x0D: // DEC r
        case 0x15: case 0x1D:
        case 0x25: case 0x2D:
        case 0x35: case 0x3D:
            val = this->get_reg((op-0x05)/8);
            val--;
            this->FLAG_H = (val & 0x0F) == 0x0F;
            this->FLAG_Z = val == 0;
            this->FLAG_N = true;
            this->set_reg((op-0x05)/8, val);
            break;

        case 0x06: case 0x0E: // LD r,n
        case 0x16: case 0x1E:
        case 0x26: case 0x2E:
        case 0x36: case 0x3E:
            this->set_reg((op-0x06)/8, arg.as_u8);
            break;

        case 0x07: // RCLA
        case 0x17: // RLA
        case 0x0F: // RRCA
        case 0x1F: // RRA
            carry = this->FLAG_C ? 1 : 0;
            if(op == 0x07) { // RCLA
                this->FLAG_C = (this->A & (1 << 7)) != 0;
                this->A = (this->A << 1) | (this->A >> 7);
            }
            if(op == 0x17) { // RLA
                this->FLAG_C = (this->A & (1 << 7)) != 0;
                this->A = (this->A << 1) | carry;
            }
            if(op == 0x0F) { // RRCA
                this->FLAG_C = (this->A & (1 << 0)) != 0;
                this->A = (this->A >> 1) | (this->A << 7);
            }
            if(op == 0x1F) { // RRA
                this->FLAG_C = (this->A & (1 << 0)) != 0;
                this->A = (this->A >> 1) | (carry << 7);
            }
            this->FLAG_N = false;
            this->FLAG_H = false;
            this->FLAG_Z = false;
            break;

        case 0x09: // ADD HL,rr
        case 0x19:
        case 0x29:
        case 0x39:
            if(op == 0x09) val16 = this->BC;
            if(op == 0x19) val16 = this->DE;
            if(op == 0x29) val16 = this->HL;
            if(op == 0x39) val16 = this->SP;
            this->FLAG_H = ((this->HL & 0x0FFF) + (val16 & 0x0FFF) > 0x0FFF);
            this->FLAG_C = (this->HL + val16 > 0xFFFF);
            this->HL += val16;
            this->FLAG_N = false;
            break;

        case 0x40 ... 0x7F: // LD r,r
            if(op == 0x76) {
                // FIXME: weird timing side effects
                this->halt = true;
                break;
            }
            this->set_reg((op - 0x40)>>3, this->get_reg(op - 0x40));
            break;

        case 0x80 ... 0x87: this->_add(this->get_reg(op)); break;
        case 0x88 ... 0x8F: this->_adc(this->get_reg(op)); break;
        case 0x90 ... 0x97: this->_sub(this->get_reg(op)); break;
        case 0x98 ... 0x9F: this->_sbc(this->get_reg(op)); break;
        case 0xA0 ... 0xA7: this->_and(this->get_reg(op)); break;
        case 0xA8 ... 0xAF: this->_xor(this->get_reg(op)); break;
        case 0xB0 ... 0xB7: this->_or(this->get_reg(op)); break;
        case 0xB8 ... 0xBF: this->_cp(this->get_reg(op)); break;
        
        case 0xC0: if(!this->FLAG_Z) this->PC = this->pop(); break;
        case 0xC1: this->BC = this->pop(); break;
        case 0xC2: if(!this->FLAG_Z) this->PC = arg.as_u16; break;
        case 0xC3: this->PC = arg.as_u16; break;
        case 0xC4: if(!this->FLAG_Z) {this->push(this->PC); this->PC = arg.as_u16;} break;
        case 0xC5: this->push(this->BC); break;
        case 0xC6: this->_add(arg.as_u8); break;
        case 0xC7: this->push(this->PC); this->PC = 0x00; break;
        case 0xC8: if(this->FLAG_Z) this->PC = this->pop(); break;
        case 0xC9: this->PC = this->pop(); break;
        case 0xCA: if(this->FLAG_Z) this->PC = arg.as_u16; break;
        // case 0xCB: break;
        case 0xCC: if(this->FLAG_Z) {this->push(this->PC); this->PC = arg.as_u16;} break;
        case 0xCD: this->push(this->PC); this->PC = arg.as_u16; break;
        case 0xCE: this->_adc(arg.as_u8); break;
        case 0xCF: this->push(this->PC); this->PC = 0x08; break;

        case 0xD0: if(!this->FLAG_C) this->PC = this->pop(); break;
        case 0xD1: this->DE = this->pop(); break;
        case 0xD2: if(!this->FLAG_C) this->PC = arg.as_u16; break;
        // case 0xD3: break;
        case 0xD4: if(!this->FLAG_C) {this->push(this->PC); this->PC = arg.as_u16;} break;
        case 0xD5: this->push(this->DE); break;
        case 0xD6: this->_sub(arg.as_u8); break;
        case 0xD7: this->push(this->PC); this->PC = 0x10; break;
        case 0xD8: if(this->FLAG_C) this->PC = this->pop(); break;
        case 0xD9: this->PC = this->pop(); this->interrupts = true; break;
        case 0xDA: if(this->FLAG_C) this->PC = arg.as_u16; break;
        // case 0xDB: break;
        case 0xDC: if(this->FLAG_C) {this->push(this->PC); this->PC = arg.as_u16;} break;
        // case 0xDD: break;
        case 0xDE: this->_sbc(arg.as_u8); break;
        case 0xDF: this->push(this->PC); this->PC = 0x18; break;

        case 0xE0: this->ram->set(0xFF00 + arg.as_u8, this->A); if(arg.as_u8 == 0x01) {putchar(this->A);}; break;
        case 0xE1: this->HL = this->pop(); break;
        case 0xE2: this->ram->set(0xFF00 + this->C, this->A); if(this->C == 0x01) {putchar(this->A);}; break;
        // case 0xE3: break;
        // case 0xE4: break;
        case 0xE5: this->push(this->HL); break;
        case 0xE6: this->_and(arg.as_u8); break;
        case 0xE7: this->push(this->PC); this->PC = 0x20; break;
        case 0xE8:
            val16 = this->SP + arg.as_i8;
            //this->FLAG_H = ((this->SP & 0x0FFF) + (arg.as_i8 & 0x0FFF) > 0x0FFF);
            //this->FLAG_C = (this->SP + arg.as_i8 > 0xFFFF);
            this->FLAG_H = ((this->SP ^ arg.as_i8 ^ val16) & 0x10 ? true : false);
            this->FLAG_C = ((this->SP ^ arg.as_i8 ^ val16) & 0x100 ? true : false);
            this->SP += arg.as_i8;
            this->FLAG_Z = false;
            this->FLAG_N = false;
            break;
        case 0xE9: this->PC = this->HL; break;
        case 0xEA: this->ram->set(arg.as_u16, this->A); break;
        // case 0xEB: break;
        // case 0xEC: break;
        // case 0xED: break;
        case 0xEE: this->_xor(arg.as_u8); break;
        case 0xEF: this->push(this->PC); this->PC = 0x28; break;

        case 0xF0: this->A = this->ram->get(0xFF00 + arg.as_u8); break;
        case 0xF1: this->AF = (this->pop() & 0xFFF0); break;
        case 0xF2: this->A = this->ram->get(0xFF00 + this->C); break;
        case 0xF3: this->interrupts = false; break;
        // case 0xF4: break;
        case 0xF5: this->push(this->AF); break;
        case 0xF6: this->_or(arg.as_u8); break;
        case 0xF7: this->push(this->PC); this->PC = 0x30; break;
        case 0xF8:
            if(arg.as_i8 >= 0) {
                this->FLAG_C = ((this->SP & 0xFF) + (arg.as_i8 & 0xFF)) > 0xFF;
                this->FLAG_H = ((this->SP & 0x0F) + (arg.as_i8 & 0x0F)) > 0x0F;
            } else {
                this->FLAG_C = ((this->SP + arg.as_i8) & 0xFF) <= (this->SP & 0xFF);
                this->FLAG_H = ((this->SP + arg.as_i8) & 0x0F) <= (this->SP & 0x0F);
            }
            // this->FLAG_H = ((((this->SP & 0x0f) + (arg.as_u8 & 0x0f)) & 0x10) != 0);
            // this->FLAG_C = ((((this->SP & 0xff) + (arg.as_u8 & 0xff)) & 0x100) != 0);
            this->HL = this->SP + arg.as_i8;
            this->FLAG_Z = false;
            this->FLAG_N = false;
            break;
        case 0xF9: this->SP = this->HL; break;
        case 0xFA: this->A = this->ram->get(arg.as_u16); break;
        case 0xFB: this->interrupts = true; break;
        case 0xFC: throw new UnitTestPassed(); // unofficial
        case 0xFD: throw new UnitTestFailed(); // unofficial
        case 0xFE: this->_cp(arg.as_u8); break;
        case 0xFF: this->push(this->PC); this->PC = 0x38; break;

        // missing ops
        default: throw new InvalidOpcode(op);
            // clang-format on
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
void CPU::tick_cb(u8 op) {
    u8 val, bit;
    bool orig_c;

    val = this->get_reg(op);
    switch(op & 0xF8) {
        // RLC
        case 0x00 ... 0x07:
            this->FLAG_C = (val & (1 << 7)) != 0;
            val <<= 1;
            if(this->FLAG_C) val |= (1 << 0);
            this->FLAG_N = false;
            this->FLAG_H = false;
            this->FLAG_Z = val == 0;
            break;

        // RRC
        case 0x08 ... 0x0F:
            this->FLAG_C = (val & (1 << 0)) != 0;
            val >>= 1;
            if(this->FLAG_C) val |= (1 << 7);
            this->FLAG_N = false;
            this->FLAG_H = false;
            this->FLAG_Z = val == 0;
            break;

        // RL
        case 0x10 ... 0x17:
            orig_c = this->FLAG_C;
            this->FLAG_C = (val & (1 << 7)) != 0;
            val <<= 1;
            if(orig_c) val |= (1 << 0);
            this->FLAG_N = false;
            this->FLAG_H = false;
            this->FLAG_Z = val == 0;
            break;

        // RR
        case 0x18 ... 0x1F:
            orig_c = this->FLAG_C;
            this->FLAG_C = (val & (1 << 0)) != 0;
            val >>= 1;
            if(orig_c) val |= (1 << 7);
            this->FLAG_N = false;
            this->FLAG_H = false;
            this->FLAG_Z = val == 0;
            break;

        // SLA
        case 0x20 ... 0x27:
            this->FLAG_C = (val & (1 << 7)) != 0;
            val <<= 1;
            val &= 0xFF;
            this->FLAG_N = false;
            this->FLAG_H = false;
            this->FLAG_Z = val == 0;
            break;

        // SRA
        case 0x28 ... 0x2F:
            this->FLAG_C = (val & (1 << 0)) != 0;
            val >>= 1;
            if(val & (1 << 6)) val |= (1 << 7);
            this->FLAG_N = false;
            this->FLAG_H = false;
            this->FLAG_Z = val == 0;
            break;

        // SWAP
        case 0x30 ... 0x37:
            val = ((val & 0xF0) >> 4) | ((val & 0x0F) << 4);
            this->FLAG_C = false;
            this->FLAG_N = false;
            this->FLAG_H = false;
            this->FLAG_Z = val == 0;
            break;

        // SRL
        case 0x38 ... 0x3F:
            this->FLAG_C = (val & (1 << 0)) != 0;
            val >>= 1;
            this->FLAG_N = false;
            this->FLAG_H = false;
            this->FLAG_Z = val == 0;
            break;

        // BIT
        case 0x40 ... 0x7F:
            bit = (op & 0b00111000) >> 3;
            this->FLAG_Z = (val & (1 << bit)) == 0;
            this->FLAG_N = false;
            this->FLAG_H = true;
            break;

        // RES
        case 0x80 ... 0xBF:
            bit = (op & 0b00111000) >> 3;
            val &= ((1 << bit) ^ 0xFF);
            break;

        // SET
        case 0xC0 ... 0xFF:
            bit = (op & 0b00111000) >> 3;
            val |= (1 << bit);
            break;

        // Should never get here
        default: printf("Op CB %02X not implemented\n", op); throw std::invalid_argument("Op not implemented");
    }
    this->set_reg(op, val);
}

void CPU::_xor(u8 val) {
    this->A ^= val;

    this->FLAG_Z = this->A == 0;
    this->FLAG_N = false;
    this->FLAG_H = false;
    this->FLAG_C = false;
}

void CPU::_or(u8 val) {
    this->A |= val;

    this->FLAG_Z = this->A == 0;
    this->FLAG_N = false;
    this->FLAG_H = false;
    this->FLAG_C = false;
}

void CPU::_and(u8 val) {
    this->A &= val;

    this->FLAG_Z = this->A == 0;
    this->FLAG_N = false;
    this->FLAG_H = true;
    this->FLAG_C = false;
}

void CPU::_cp(u8 val) {
    this->FLAG_Z = this->A == val;
    this->FLAG_N = true;
    this->FLAG_H = (this->A & 0x0F) < (val & 0x0F);
    this->FLAG_C = this->A < val;
}

void CPU::_add(u8 val) {
    this->FLAG_C = this->A + val > 0xFF;
    this->FLAG_H = (this->A & 0x0F) + (val & 0x0F) > 0x0F;
    this->FLAG_N = false;
    this->A += val;
    this->FLAG_Z = this->A == 0;
}

void CPU::_adc(u8 val) {
    int carry = this->FLAG_C ? 1 : 0;
    this->FLAG_C = this->A + val + carry > 0xFF;
    this->FLAG_H = (this->A & 0x0F) + (val & 0x0F) + carry > 0x0F;
    this->FLAG_N = false;
    this->A += val + carry;
    this->FLAG_Z = this->A == 0;
}

void CPU::_sub(u8 val) {
    this->FLAG_C = this->A < val;
    this->FLAG_H = (this->A & 0x0F) < (val & 0x0F);
    this->A -= val;
    this->FLAG_Z = this->A == 0;
    this->FLAG_N = true;
}

void CPU::_sbc(u8 val) {
    int carry = this->FLAG_C ? 1 : 0;
    auto res = this->A - val - carry;
    this->FLAG_H = ((this->A ^ val ^ (res & 0xff)) & (1 << 4)) != 0;
    this->FLAG_C = res < 0;
    this->A -= val + carry;
    this->FLAG_Z = this->A == 0;
    this->FLAG_N = true;
}

void CPU::push(u16 val) {
    this->ram->set(this->SP - 1, ((val & 0xFF00) >> 8) & 0xFF);
    this->ram->set(this->SP - 2, val & 0xFF);
    this->SP -= 2;
}

u16 CPU::pop() {
    u16 val = (this->ram->get(this->SP + 1) << 8) | this->ram->get(this->SP);
    this->SP += 2;
    return val;
}

u8 CPU::get_reg(u8 n) {
    switch(n & 0x07) {
        case 0: return this->B; break;
        case 1: return this->C; break;
        case 2: return this->D; break;
        case 3: return this->E; break;
        case 4: return this->H; break;
        case 5: return this->L; break;
        case 6: return this->ram->get(this->HL); break;
        case 7: return this->A; break;
        default: printf("Invalid register %d\n", n); return 0;
    }
}

void CPU::set_reg(u8 n, u8 val) {
    switch(n & 0x07) {
        case 0: this->B = val; break;
        case 1: this->C = val; break;
        case 2: this->D = val; break;
        case 3: this->E = val; break;
        case 4: this->H = val; break;
        case 5: this->L = val; break;
        case 6: this->ram->set(this->HL, val); break;
        case 7: this->A = val; break;
        default: printf("Invalid register %d\n", n);
    }
}
