import { Interrupt } from "./consts";
import { RAM } from "./ram";
import { Mem } from "./consts";
import { InvalidOpcode, UnitTestFailed, UnitTestPassed } from "./errors";
import { hex } from "./_utils";

// prettier-ignore
const OP_CYCLES = [
    1, 3, 2, 2, 1, 1, 2, 1, 5, 2, 2, 2, 1, 1, 2, 1,
    0, 3, 2, 2, 1, 1, 2, 1, 3, 2, 2, 2, 1, 1, 2, 1,
    2, 3, 2, 2, 1, 1, 2, 1, 2, 2, 2, 2, 1, 1, 2, 1,
    2, 3, 2, 2, 3, 3, 3, 1, 2, 2, 2, 2, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    2, 2, 2, 2, 2, 2, 0, 2, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    2, 3, 3, 4, 3, 4, 2, 4, 2, 4, 3, 0, 3, 6, 2, 4,
    2, 3, 3, 0, 3, 4, 2, 4, 2, 4, 3, 0, 3, 0, 2, 4,
    3, 3, 2, 0, 0, 4, 2, 4, 4, 1, 4, 0, 0, 0, 2, 4,
    3, 3, 2, 1, 0, 4, 2, 4, 3, 2, 4, 1, 0, 0, 2, 4,
];

// prettier-ignore
const OP_CB_CYCLES = [
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2,
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2,
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2,
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
];

// prettier-ignore
const OP_ARG_TYPES = [
    //1 2 3 4 5 6 7 8 9 A B C D E F
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

const OP_ARG_BYTES = [0, 1, 2, 1];

// prettier-ignore
const OP_NAMES = [
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
];

// prettier-ignore
const CB_OP_NAMES = [
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

class oparg {
    // FIXME should be a union
    as_u8: u8 = 0;
    as_i8: i8 = 0;
    as_u16: u16 = 0;
}

function int8(val: number): i8 {
    val = val & 0xff;
    if (val > 127) {
        val -= 0x100;
    }
    return val;
}

function uint8(val: number): u8 {
    return val & 0xff;
}

function uint16(val: number): u16 {
    return val & 0xffff;
}

function split16(val: number): [u8, u8] {
    return [uint8(val >> 8), uint8(val & 0xff)];
}

function join16(a: u8, b: u8): u16 {
    return (uint16(a) << 8) | uint16(b);
}

export class CPU {
    ram: RAM;
    debug: boolean;
    stop: boolean;
    halt: boolean;

    flag_c: boolean;
    flag_h: boolean;
    flag_n: boolean;
    flag_z: boolean;
    pc: u16;
    sp: u16;
    hl: u16;
    f: u8;
    e: u8;
    d: u8;
    c: u8;
    b: u8;
    a: u8;
    cycle: number;
    interrupts: boolean;
    owed_cycles: number;

    constructor(ram: RAM, debug: boolean) {
        this.ram = ram;
        this.debug = debug;
        this.stop = false;

        this.stop = false;
        this.halt = false;
        this.owed_cycles = 0;
        this.interrupts = false;
        this.cycle = 0;

        // FIXME: these should be unioned
        // A, B, C, D, E, H, L, F         uint8
        // AF, BC, DE, HL, SP, PC         uint16
        this.a = 0;
        this.b = 0;
        this.c = 0;
        this.d = 0;
        this.e = 0;
        this.f = 0;
        this.hl = 0;
        this.sp = 0;
        this.pc = 0;
        this.flag_z = false;
        this.flag_n = false;
        this.flag_h = false;
        this.flag_c = false;
    }

    tick(): void {
        this.tick_dma();
        this.tick_clock();
        this.tick_interrupts();
        if (this.halt) {
            return;
        }
        if (this.stop) {
            return;
        }
        this.tick_instructions();
    }

    interrupt(i: Interrupt): void {
        // Set a given interrupt bit - on the next tick, if the interrupt
        // handler for self interrupt is enabled (and interrupts in general
        // are enabled), then the interrupt handler will be called.
        this.ram.set(Mem.IF, this.ram.get(Mem.IF) | i);
        this.halt = false; // interrupts interrupt HALT state
    }

    dump_regs(): void {
        // stack
        const sp_val =
            this.ram.get(this.sp) | (this.ram.get((this.sp + 1) & 0xffff) << 8);

        // interrupts
        const IE = this.ram.get(Mem.IE);
        const IF = this.ram.get(Mem.IF);
        const z = (this.f >> 7) & 1 ? "Z" : "z";
        const n = (this.f >> 6) & 1 ? "N" : "n";
        const h = (this.f >> 5) & 1 ? "H" : "h";
        const c = (this.f >> 4) & 1 ? "C" : "c";
        const v = (IE >> 0) & 1 ? ((IF >> 0) & 1 ? "V" : "v") : "_";
        const l = (IE >> 1) & 1 ? ((IF >> 1) & 1 ? "L" : "l") : "_";
        const t = (IE >> 2) & 1 ? ((IF >> 2) & 1 ? "T" : "t") : "_";
        const s = (IE >> 3) & 1 ? ((IF >> 3) & 1 ? "S" : "s") : "_";
        const j = (IE >> 4) & 1 ? ((IF >> 4) & 1 ? "J" : "j") : "_";

        // opcode & args
        let op = this.ram.get(this.pc);
        let op_str = "";
        if (op == 0xcb) {
            op = this.ram.get(this.pc + 1);
            op_str = CB_OP_NAMES[op];
        } else {
            switch (OP_ARG_TYPES[op]) {
                case 0:
                    op_str = OP_NAMES[op];
                    break;
                case 1:
                    op_str = OP_NAMES[op].replace(
                        "u8",
                        hex(this.ram.get(this.pc + 1), 2),
                    );
                    break;
                case 2:
                    op_str = OP_NAMES[op].replace(
                        "u16",
                        hex(
                            uint16(this.ram.get(this.pc + 1)) |
                                (uint16(this.ram.get(this.pc + 2)) << 8),
                            4,
                        ),
                    );
                    break;
                case 3:
                    op_str = OP_NAMES[op].replace(
                        "i8",
                        int8(this.ram.get(this.pc + 1)).toString(),
                    );
                    break;
            }
        }

        // print
        console.log(
            `${hex(this.a, 2)}${hex(this.f, 2)} ` +
                `${hex(this.b, 2)}${hex(this.c, 2)} ` +
                `${hex(this.d, 2)}${hex(this.e, 2)} ` +
                `${hex(this.hl, 4)} : ${hex(this.sp, 4)} = ${hex(sp_val, 4)} ` +
                `: ${z}${n}${h}${c} : ${v}${l}${t}${s}${j} ` +
                `: ${hex(this.pc, 4)} = ${hex(op, 2)} : ${op_str}`,
        );
    }

    tick_dma(): void {
        // TODO: DMA should take 26 cycles, during which main RAM is inaccessible
        if (this.ram.get(Mem.DMA) > 0) {
            const dma_src = uint16(this.ram.get(Mem.DMA)) << 8;
            for (let i = 0; i < 0x60; i++) {
                this.ram.set(
                    uint16(Mem.OamBase + i),
                    this.ram.get(dma_src + uint16(i)),
                );
            }
            this.ram.set(Mem.DMA, 0x00);
        }
    }

    tick_clock(): void {
        this.cycle++;

        // TODO: writing any value to Mem.DIV should reset it to 0x00
        // increment at 16384Hz (each 64 cycles?)
        if (this.cycle % 64 == 0) {
            this.ram.set(Mem.DIV, (this.ram.get(Mem.DIV) + 1) & 0xff);
        }

        if ((this.ram.get(Mem.TAC) & (1 << 2)) > 0) {
            // timer enable
            const speeds = [256, 4, 16, 64]; // increment per X cycles
            const speed = speeds[this.ram.get(Mem.TAC) & 0x03];
            if (this.cycle % speed == 0) {
                if (this.ram.get(Mem.TIMA) == 0xff) {
                    this.ram.set(Mem.TIMA, this.ram.get(Mem.TMA)); // if timer overflows, load base
                    this.interrupt(Interrupt.TIMER);
                }
                this.ram.set(Mem.TIMA, (this.ram.get(Mem.TIMA) + 1) & 0xff);
            }
        }
    }

    check_interrupt(queue: u8, i: Interrupt, handler: u16): boolean {
        if ((queue & i) > 0) {
            // TODO: wait two cycles
            // TODO: push16(PC) should also take two cycles
            // TODO: one more cycle to store new PC
            this.push(this.pc);
            this.pc = handler;
            this.ram.set(Mem.IF, this.ram.get(Mem.IF) & ~i);
            return true;
        }
        return false;
    }

    tick_interrupts(): void {
        const queue = this.ram.get(Mem.IE) & this.ram.get(Mem.IF);
        if (this.interrupts && queue != 0x00) {
            if (this.debug) {
                console.log(
                    `Handling interrupts: ${hex(
                        this.ram.get(Mem.IE),
                        2,
                    )} & ${hex(this.ram.get(Mem.IF), 2)}`,
                );
            }
            this.interrupts = false; // no nested interrupts, RETI will re-enable
            this.check_interrupt(queue, Interrupt.VBLANK, Mem.VBlankHandler) ||
                this.check_interrupt(queue, Interrupt.STAT, Mem.LcdHandler) ||
                this.check_interrupt(
                    queue,
                    Interrupt.TIMER,
                    Mem.TimerHandler,
                ) ||
                this.check_interrupt(
                    queue,
                    Interrupt.SERIAL,
                    Mem.SerialHandler,
                ) ||
                this.check_interrupt(
                    queue,
                    Interrupt.JOYPAD,
                    Mem.JoypadHandler,
                );
        }
    }

    tick_instructions(): void {
        // if the previous instruction was large, let's not run any
        // more instructions until other subsystems have caught up
        if (this.owed_cycles > 0) {
            this.owed_cycles--;
            return;
        }

        if (this.debug) {
            this.dump_regs();
        }

        let op = this.ram.get(this.pc);
        if (op == 0xcb) {
            op = this.ram.get(this.pc + 1);
            this.pc += 2;
            this.tick_cb(op);
            this.owed_cycles = OP_CB_CYCLES[op] - 1;
        } else {
            let arg = new oparg();
            let arg_len = OP_ARG_BYTES[OP_ARG_TYPES[op]];
            if (arg_len == 1) {
                arg.as_u8 = this.ram.get(this.pc + 1);
                arg.as_i8 = int8(arg.as_u8);
            }
            if (arg_len == 2) {
                const low = this.ram.get(this.pc + 1);
                const high = this.ram.get(this.pc + 2);
                arg.as_u16 = uint16(low) | (uint16(high) << 8);
            }
            this.pc += 1 + arg_len;

            this.tick_main(op, arg);
            this.owed_cycles = OP_CYCLES[op] - 1;
        }

        // Flags should be union'ed with the F register, but php doesn't
        // support that, so let's manually sync from flags to register
        // after every instruction...
        this.f = 0;
        if (this.flag_z) {
            this.f |= 1 << 7;
        }
        if (this.flag_n) {
            this.f |= 1 << 6;
        }
        if (this.flag_h) {
            this.f |= 1 << 5;
        }
        if (this.flag_c) {
            this.f |= 1 << 4;
        }

        // HALT has cycles=0
        if (this.owed_cycles < 0) {
            this.owed_cycles = 0;
        }
    }

    tick_main(op: u8, arg: oparg): void {
        // Execute
        switch (op) {
            case 0x00 /* NOP */:
                break;
            case 0x01:
                [this.b, this.c] = split16(arg.as_u16);
                break;
            case 0x02:
                this.ram.set(join16(this.b, this.c), this.a);
                break;
            case 0x03:
                [this.b, this.c] = split16(join16(this.b, this.c) + 1);
                break;
            case 0x08:
                this.ram.set(arg.as_u16 + 1, uint8((this.sp >> 8) & 0xff));
                this.ram.set(arg.as_u16, uint8(this.sp & 0xff));
                break;
            case 0x0a:
                this.a = this.ram.get(join16(this.b, this.c));
                break;
            case 0x0b:
                [this.b, this.c] = split16(join16(this.b, this.c) - 1);
                break;
            case 0x10:
                this.stop = true;
                break;
            case 0x11:
                [this.d, this.e] = split16(arg.as_u16);
                break;
            case 0x12:
                this.ram.set(join16(this.d, this.e), this.a);
                break;
            case 0x13:
                [this.d, this.e] = split16(join16(this.d, this.e) + 1);
                break;
            case 0x18:
                this.pc += arg.as_i8;
                break;
            case 0x1a:
                this.a = this.ram.get(join16(this.d, this.e));
                break;
            case 0x1b:
                [this.d, this.e] = split16(join16(this.d, this.e) - 1);
                break;

            case 0x20:
                if (!this.flag_z) {
                    this.pc += arg.as_i8;
                }
                break;
            case 0x21:
                this.hl = arg.as_u16;
                break;
            case 0x22:
                this.ram.set(this.hl, this.a);
                this.hl = (this.hl + 1) & 0xffff;
                break;
            case 0x23:
                this.hl = (this.hl + 1) & 0xffff;
                break;
            case 0x27:
                var val16 = uint16(this.a);
                if (!this.flag_n) {
                    if (this.flag_h || (val16 & 0x0f) > 9) {
                        val16 += 6;
                    }
                    if (this.flag_c || val16 > 0x9f) {
                        val16 += 0x60;
                    }
                } else {
                    if (this.flag_h) {
                        val16 -= 6;
                        if (!this.flag_c) {
                            val16 &= 0xff;
                        }
                    }
                    if (this.flag_c) {
                        val16 -= 0x60;
                    }
                }
                this.flag_h = false;
                if ((val16 & 0x100) > 0) {
                    this.flag_c = true;
                }
                this.a = uint8(val16 & 0xff);
                this.flag_z = this.a == 0;
                break;
            case 0x28:
                if (this.flag_z) {
                    this.pc += arg.as_i8;
                }
                break;
            case 0x2a:
                this.a = this.ram.get(this.hl);
                this.hl = (this.hl + 1) & 0xffff;
                break;
            case 0x2b:
                this.hl = (this.hl - 1) & 0xffff;
                break;
            case 0x2f:
                this.a ^= 0xff;
                this.flag_n = true;
                this.flag_h = true;
                break;
            case 0x30:
                if (!this.flag_c) {
                    this.pc += arg.as_i8;
                }
                break;
            case 0x31:
                this.sp = arg.as_u16;
                break;
            case 0x32:
                this.ram.set(this.hl, this.a);
                this.hl = (this.hl - 1) & 0xffff;
                break;
            case 0x33:
                this.sp = (this.sp + 1) & 0xffff;
                break;
            case 0x37:
                this.flag_n = false;
                this.flag_h = false;
                this.flag_c = true;
                break;
            case 0x38:
                if (this.flag_c) {
                    this.pc += arg.as_i8;
                }
                break;
            case 0x3a:
                this.a = this.ram.get(this.hl);
                this.hl = (this.hl - 1) & 0xffff;
                break;
            case 0x3b:
                this.sp = (this.sp - 1) & 0xffff;
                break;
            case 0x3f:
                this.flag_c = !this.flag_c;
                this.flag_n = false;
                this.flag_h = false;
                break;

            // INC r
            case 0x04:
            case 0x0c:
            case 0x14:
            case 0x1c:
            case 0x24:
            case 0x2c:
            case 0x34:
            case 0x3c:
                var val = this.get_reg((op - 0x04) / 8);
                this.flag_h = (val & 0x0f) == 0x0f;
                val = (val + 1) & 0xff;
                this.flag_z = val == 0;
                this.flag_n = false;
                this.set_reg((op - 0x04) / 8, val);
                break;

            // DEC r
            case 0x05:
            case 0x0d:
            case 0x15:
            case 0x1d:
            case 0x25:
            case 0x2d:
            case 0x35:
            case 0x3d:
                var val = this.get_reg((op - 0x05) / 8);
                val = (val - 1) & 0xff;
                this.flag_h = (val & 0x0f) == 0x0f;
                this.flag_z = val == 0;
                this.flag_n = true;
                this.set_reg((op - 0x05) / 8, val);
                break;

            // LD r,n
            case 0x06:
            case 0x0e:
            case 0x16:
            case 0x1e:
            case 0x26:
            case 0x2e:
            case 0x36:
            case 0x3e:
                this.set_reg((op - 0x06) / 8, arg.as_u8);
                break;

            // RCLA, RLA, RRCA, RRA
            case 0x07:
            case 0x17:
            case 0x0f:
            case 0x1f:
                const carry = this.flag_c ? 1 : 0;
                if (op == 0x07) {
                    // RCLA
                    this.flag_c = (this.a & (1 << 7)) != 0;
                    this.a = (this.a << 1) | (this.a >> 7);
                }
                if (op == 0x17) {
                    // RLA
                    this.flag_c = (this.a & (1 << 7)) != 0;
                    this.a = (this.a << 1) | carry;
                }
                if (op == 0x0f) {
                    // RRCA
                    this.flag_c = (this.a & (1 << 0)) != 0;
                    this.a = (this.a >> 1) | (this.a << 7);
                }
                if (op == 0x1f) {
                    // RRA
                    this.flag_c = (this.a & (1 << 0)) != 0;
                    this.a = (this.a >> 1) | (carry << 7);
                }
                this.a &= 0xff;
                this.flag_n = false;
                this.flag_h = false;
                this.flag_z = false;
                break;

            // ADD HL,rr
            case 0x09:
            case 0x19:
            case 0x29:
            case 0x39:
                var val16 = -1;
                if (op == 0x09) {
                    val16 = join16(this.b, this.c);
                }
                if (op == 0x19) {
                    val16 = join16(this.d, this.e);
                }
                if (op == 0x29) {
                    val16 = this.hl;
                }
                if (op == 0x39) {
                    val16 = this.sp;
                }
                this.flag_h = (this.hl & 0x0fff) + (val16 & 0x0fff) > 0x0fff;
                this.flag_c = this.hl + val16 > 0xffff;
                this.hl = (this.hl + val16) & 0xffff;
                this.flag_n = false;
                break;

            // LD r,r
            case 0x40:
            case 0x41:
            case 0x42:
            case 0x43:
            case 0x44:
            case 0x45:
            case 0x46:
            case 0x47:
            case 0x48:
            case 0x49:
            case 0x4a:
            case 0x4b:
            case 0x4c:
            case 0x4d:
            case 0x4e:
            case 0x4f:
            case 0x50:
            case 0x51:
            case 0x52:
            case 0x53:
            case 0x54:
            case 0x55:
            case 0x56:
            case 0x57:
            case 0x58:
            case 0x59:
            case 0x5a:
            case 0x5b:
            case 0x5c:
            case 0x5d:
            case 0x5e:
            case 0x5f:
            case 0x60:
            case 0x61:
            case 0x62:
            case 0x63:
            case 0x64:
            case 0x65:
            case 0x66:
            case 0x67:
            case 0x68:
            case 0x69:
            case 0x6a:
            case 0x6b:
            case 0x6c:
            case 0x6d:
            case 0x6e:
            case 0x6f:
            case 0x70:
            case 0x71:
            case 0x72:
            case 0x73:
            case 0x74:
            case 0x75:
            case 0x76:
            case 0x77:
            case 0x78:
            case 0x79:
            case 0x7a:
            case 0x7b:
            case 0x7c:
            case 0x7d:
            case 0x7e:
            case 0x7f:
                if (op == 0x76) {
                    // FIXME: weird timing side effects
                    this.halt = true;
                    break;
                }
                this.set_reg((op - 0x40) >> 3, this.get_reg(op - 0x40));
                break;
            case 0x80:
            case 0x81:
            case 0x82:
            case 0x83:
            case 0x84:
            case 0x85:
            case 0x86:
            case 0x87:
                this._add(this.get_reg(op));
                break;
            case 0x88:
            case 0x89:
            case 0x8a:
            case 0x8b:
            case 0x8c:
            case 0x8d:
            case 0x8e:
            case 0x8f:
                this._adc(this.get_reg(op));
                break;
            case 0x90:
            case 0x91:
            case 0x92:
            case 0x93:
            case 0x94:
            case 0x95:
            case 0x96:
            case 0x97:
                this._sub(this.get_reg(op));
                break;
            case 0x98:
            case 0x99:
            case 0x9a:
            case 0x9b:
            case 0x9c:
            case 0x9d:
            case 0x9e:
            case 0x9f:
                this._sbc(this.get_reg(op));
                break;
            case 0xa0:
            case 0xa1:
            case 0xa2:
            case 0xa3:
            case 0xa4:
            case 0xa5:
            case 0xa6:
            case 0xa7:
                this._and(this.get_reg(op));
                break;
            case 0xa8:
            case 0xa9:
            case 0xaa:
            case 0xab:
            case 0xac:
            case 0xad:
            case 0xae:
            case 0xaf:
                this._xor(this.get_reg(op));
                break;
            case 0xb0:
            case 0xb1:
            case 0xb2:
            case 0xb3:
            case 0xb4:
            case 0xb5:
            case 0xb6:
            case 0xb7:
                this._or(this.get_reg(op));
                break;
            case 0xb8:
            case 0xb9:
            case 0xba:
            case 0xbb:
            case 0xbc:
            case 0xbd:
            case 0xbe:
            case 0xbf:
                this._cp(this.get_reg(op));
                break;

            case 0xc0:
                if (!this.flag_z) {
                    this.pc = this.pop();
                }
                break;
            case 0xc1:
                [this.b, this.c] = split16(this.pop());
                break;
            case 0xc2:
                if (!this.flag_z) {
                    this.pc = arg.as_u16;
                }
                break;
            case 0xc3:
                this.pc = arg.as_u16;
                break;
            case 0xc4:
                if (!this.flag_z) {
                    this.push(this.pc);
                    this.pc = arg.as_u16;
                }
                break;
            case 0xc5:
                this.push(join16(this.b, this.c));
                break;
            case 0xc6:
                this._add(arg.as_u8);
                break;
            case 0xc7:
                this.push(this.pc);
                this.pc = 0x00;
                break;
            case 0xc8:
                if (this.flag_z) {
                    this.pc = this.pop();
                }
                break;
            case 0xc9:
                this.pc = this.pop();
                break;
            case 0xca:
                if (this.flag_z) {
                    this.pc = arg.as_u16;
                }
                break;
            // case 0xCB: break;
            case 0xcc:
                if (this.flag_z) {
                    this.push(this.pc);
                    this.pc = arg.as_u16;
                }
                break;
            case 0xcd:
                this.push(this.pc);
                this.pc = arg.as_u16;
                break;
            case 0xce:
                this._adc(arg.as_u8);
                break;
            case 0xcf:
                this.push(this.pc);
                this.pc = 0x08;
                break;

            case 0xd0:
                if (!this.flag_c) {
                    this.pc = this.pop();
                }
                break;
            case 0xd1:
                [this.d, this.e] = split16(this.pop());
                break;
            case 0xd2:
                if (!this.flag_c) {
                    this.pc = arg.as_u16;
                }
                break;
            // case 0xD3: break;
            case 0xd4:
                if (!this.flag_c) {
                    this.push(this.pc);
                    this.pc = arg.as_u16;
                }
                break;
            case 0xd5:
                this.push(join16(this.d, this.e));
                break;
            case 0xd6:
                this._sub(arg.as_u8);
                break;
            case 0xd7:
                this.push(this.pc);
                this.pc = 0x10;
                break;
            case 0xd8:
                if (this.flag_c) {
                    this.pc = this.pop();
                }
                break;
            case 0xd9:
                this.pc = this.pop();
                this.interrupts = true;
                break;
            case 0xda:
                if (this.flag_c) {
                    this.pc = arg.as_u16;
                }
                break;
            // case 0xDB: break;
            case 0xdc:
                if (this.flag_c) {
                    this.push(this.pc);
                    this.pc = arg.as_u16;
                }
                break;
            // case 0xDD: break;
            case 0xde:
                this._sbc(arg.as_u8);
                break;
            case 0xdf:
                this.push(this.pc);
                this.pc = 0x18;
                break;
            case 0xe0:
                this.ram.set(0xff00 + uint16(arg.as_u8), this.a);
                if (arg.as_u8 == 0x01) {
                    process.stdout.write(String.fromCharCode(this.a));
                }
                break;
            case 0xe1:
                this.hl = this.pop();
                break;
            case 0xe2:
                this.ram.set(0xff00 + uint16(this.c), this.a);
                if (this.c == 0x01) {
                    process.stdout.write(String.fromCharCode(this.a));
                }
                break;
            // case 0xE3: break;
            // case 0xE4: break;
            case 0xe5:
                this.push(this.hl);
                break;
            case 0xe6:
                this._and(arg.as_u8);
                break;
            case 0xe7:
                this.push(this.pc);
                this.pc = 0x20;
                break;
            case 0xe8:
                val16 = (this.sp + arg.as_i8) & 0xffff;
                //this.flag_h = ((this.sp & 0x0FFF) + (arg.as_i8 & 0x0FFF) > 0x0FFF);
                //this.flag_c = (this.sp + arg.as_i8 > 0xFFFF);
                this.flag_h =
                    ((this.sp ^ uint16(arg.as_i8) ^ val16) & 0x10) > 0;
                this.flag_c =
                    ((this.sp ^ uint16(arg.as_i8) ^ val16) & 0x100) > 0;
                this.sp = (this.sp + arg.as_i8) & 0xffff;
                this.flag_z = false;
                this.flag_n = false;
                break;
            case 0xe9:
                this.pc = this.hl;
                break;
            case 0xea:
                this.ram.set(arg.as_u16, this.a);
                break;
            // case 0xEB: break;
            // case 0xEC: break;
            // case 0xED: break;
            case 0xee:
                this._xor(arg.as_u8);
                break;
            case 0xef:
                this.push(this.pc);
                this.pc = 0x28;
                break;

            case 0xf0:
                this.a = this.ram.get(0xff00 + uint16(arg.as_u8));
                break;
            case 0xf1:
                [this.a, this.f] = split16(this.pop() & 0xfff0);
                this.flag_z = (this.f & (1 << 7)) > 0;
                this.flag_n = (this.f & (1 << 6)) > 0;
                this.flag_h = (this.f & (1 << 5)) > 0;
                this.flag_c = (this.f & (1 << 4)) > 0;
                break;
            case 0xf2:
                this.a = this.ram.get(0xff00 + uint16(this.c));
                break;
            case 0xf3:
                this.interrupts = false;
                break;
            // case 0xF4: break;
            case 0xf5:
                this.push(join16(this.a, this.f));
                break;
            case 0xf6:
                this._or(arg.as_u8);
                break;
            case 0xf7:
                this.push(this.pc);
                this.pc = 0x30;
                break;
            case 0xf8:
                if (arg.as_i8 >= 0) {
                    this.flag_c = (this.sp & 0xff) + (arg.as_i8 & 0xff) > 0xff;
                    this.flag_h = (this.sp & 0x0f) + (arg.as_i8 & 0x0f) > 0x0f;
                } else {
                    this.flag_c =
                        uint8((this.sp + arg.as_i8) & 0xff) <=
                        uint8(this.sp & 0xff);
                    this.flag_h =
                        uint8((this.sp + arg.as_i8) & 0x0f) <=
                        uint8(this.sp & 0x0f);
                }
                // this.flag_h = ((((this.sp & 0x0f) + (arg.as_u8 & 0x0f)) & 0x10) != 0);
                // this.flag_c = ((((this.sp & 0xff) + (arg.as_u8 & 0xff)) & 0x100) != 0);
                this.hl = (this.sp + arg.as_i8) & 0xffff;
                this.flag_z = false;
                this.flag_n = false;
                break;
            case 0xf9:
                this.sp = this.hl;
                break;
            case 0xfa:
                this.a = this.ram.get(arg.as_u16);
                break;
            case 0xfb:
                this.interrupts = true;
                break;
            case 0xfc:
                throw new UnitTestPassed();
            case 0xfd:
                throw new UnitTestFailed();
            case 0xfe:
                this._cp(arg.as_u8);
                break;
            case 0xff:
                this.push(this.pc);
                this.pc = 0x38;
                break;

            // missing ops
            default:
                throw new InvalidOpcode(op);
        }
    }

    tick_cb(op: u8) {
        var val = this.get_reg(op);
        switch (true) {
            // RLC
            case op <= 0x07:
                this.flag_c = (val & (1 << 7)) != 0;
                val <<= 1;
                val &= 0xff;
                if (this.flag_c) {
                    val |= 1 << 0;
                }
                this.flag_n = false;
                this.flag_h = false;
                this.flag_z = val == 0;
                break;

            // RRC
            case op <= 0x0f:
                this.flag_c = (val & (1 << 0)) != 0;
                val >>= 1;
                if (this.flag_c) {
                    val |= 1 << 7;
                }
                this.flag_n = false;
                this.flag_h = false;
                this.flag_z = val == 0;
                break;

            // RL
            case op <= 0x17:
                var orig_c = this.flag_c;
                this.flag_c = (val & (1 << 7)) != 0;
                val <<= 1;
                val &= 0xff;
                if (orig_c) {
                    val |= 1 << 0;
                }
                this.flag_n = false;
                this.flag_h = false;
                this.flag_z = val == 0;
                break;

            // RR
            case op <= 0x1f:
                var orig_c = this.flag_c;
                this.flag_c = (val & (1 << 0)) != 0;
                val >>= 1;
                if (orig_c) {
                    val |= 1 << 7;
                }
                this.flag_n = false;
                this.flag_h = false;
                this.flag_z = val == 0;
                break;

            // SLA
            case op <= 0x27:
                this.flag_c = (val & (1 << 7)) != 0;
                val <<= 1;
                val &= 0xff;
                this.flag_n = false;
                this.flag_h = false;
                this.flag_z = val == 0;
                break;

            // SRA
            case op <= 0x2f:
                this.flag_c = (val & (1 << 0)) != 0;
                val >>= 1;
                if ((val & (1 << 6)) > 0) {
                    val |= 1 << 7;
                }
                this.flag_n = false;
                this.flag_h = false;
                this.flag_z = val == 0;
                break;

            // SWAP
            case op <= 0x37:
                val = ((val & 0xf0) >> 4) | ((val & 0x0f) << 4);
                this.flag_c = false;
                this.flag_n = false;
                this.flag_h = false;
                this.flag_z = val == 0;
                break;

            // SRL
            case op <= 0x3f:
                this.flag_c = (val & (1 << 0)) != 0;
                val >>= 1;
                this.flag_n = false;
                this.flag_h = false;
                this.flag_z = val == 0;
                break;

            // BIT
            case op <= 0x7f:
                var bit = (op & 0b00111000) >> 3;
                this.flag_z = (val & (1 << bit)) == 0;
                this.flag_n = false;
                this.flag_h = true;
                break;

            // RES
            case op <= 0xbf:
                var bit = (op & 0b00111000) >> 3;
                val &= (1 << bit) ^ 0xff;
                break;

            // SET
            case op <= 0xff:
                var bit = (op & 0b00111000) >> 3;
                val |= 1 << bit;
                break;

            // Should never get here
            default:
                throw new Error("Unreachable code reached in tick_cb");
        }
        this.set_reg(op, val);
    }

    _xor(val: u8) {
        this.a ^= val;

        this.flag_z = this.a == 0;
        this.flag_n = false;
        this.flag_h = false;
        this.flag_c = false;
    }

    _or(val: u8) {
        this.a |= val;

        this.flag_z = this.a == 0;
        this.flag_n = false;
        this.flag_h = false;
        this.flag_c = false;
    }

    _and(val: u8) {
        this.a &= val;

        this.flag_z = this.a == 0;
        this.flag_n = false;
        this.flag_h = true;
        this.flag_c = false;
    }

    _cp(val: u8) {
        this.flag_z = this.a == val;
        this.flag_n = true;
        this.flag_h = (this.a & 0x0f) < (val & 0x0f);
        this.flag_c = this.a < val;
    }

    _add(val: u8) {
        this.flag_c = uint16(this.a) + uint16(val) > 0xff;
        this.flag_h = (this.a & 0x0f) + (val & 0x0f) > 0x0f;
        this.flag_n = false;
        this.a = (this.a + val) & 0xff;
        this.flag_z = this.a == 0;
    }

    _adc(val: u8) {
        const carry = this.flag_c ? 1 : 0;
        this.flag_c = uint16(this.a) + uint16(val) + uint16(carry) > 0xff;
        this.flag_h = (this.a & 0x0f) + (val & 0x0f) + carry > 0x0f;
        this.flag_n = false;
        this.a = (this.a + val + carry) & 0xff;
        this.flag_z = this.a == 0;
    }

    _sub(val: u8) {
        this.flag_c = this.a < val;
        this.flag_h = (this.a & 0x0f) < (val & 0x0f);
        this.a = (this.a - val) & 0xff;
        this.flag_z = this.a == 0;
        this.flag_n = true;
    }

    _sbc(val: u8) {
        const carry = this.flag_c ? 1 : 0;
        const res = this.a - val - carry;
        this.flag_h = ((this.a ^ val ^ (uint8(res) & 0xff)) & (1 << 4)) != 0;
        this.flag_c = res < 0;
        this.a = (this.a - val - carry) & 0xff;
        this.flag_z = this.a == 0;
        this.flag_n = true;
    }

    push(val: u16) {
        this.ram.set(this.sp - 1, uint8(((val & 0xff00) >> 8) & 0xff));
        this.ram.set(this.sp - 2, uint8(val & 0xff));
        this.sp -= 2;
    }

    pop(): u16 {
        var val =
            (uint16(this.ram.get(this.sp + 1)) << 8) |
            uint16(this.ram.get(this.sp));
        this.sp += 2;
        return val;
    }

    get_reg(n: u8): u8 {
        switch (n & 0x07) {
            case 0:
                return this.b;
            case 1:
                return this.c;
            case 2:
                return this.d;
            case 3:
                return this.e;
            case 4:
                return uint8(this.hl >> 8);
            case 5:
                return uint8(this.hl & 0xff);
            case 6:
                return this.ram.get(this.hl);
            case 7:
                return this.a;
            default:
                throw new Error("Unreachable code reached in get_reg");
        }
    }

    set_reg(n: u8, val: u8) {
        switch (n & 0x07) {
            case 0:
                this.b = val;
                break;
            case 1:
                this.c = val;
                break;
            case 2:
                this.d = val;
                break;
            case 3:
                this.e = val;
                break;
            case 4:
                var [_, orig_l] = split16(this.hl);
                this.hl = join16(val, orig_l);
                break;
            case 5:
                var [orig_h, _] = split16(this.hl);
                this.hl = join16(orig_h, val);
                break;
            case 6:
                this.ram.set(this.hl, val);
                break;
            case 7:
                this.a = val;
                break;
            default:
                throw new Error("Unreachable code reached in set_reg");
        }
    }
}
