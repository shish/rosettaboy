
#include "cpu.h"
#include "cart.h"
#include "consts.h"
#include "errors.h"
#include "ram.h"

static const u8 OP_CYCLES[] = {
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

static const u8 OP_CB_CYCLES[] = {
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

static const u8 OP_ARG_TYPES[] = {
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

static const u8 OP_ARG_BYTES[] = {0, 1, 2, 1};

const char *const OP_NAMES[] = {
    "NOP",           "LD BC,$%04X", "LD [BC],A",     "INC BC",      "INC B",         "DEC B",
    "LD B,$%02X",    "RCLA",        "LD [$%04X],SP", "ADD HL,BC",   "LD A,[BC]",     "DEC BC",
    "INC C",         "DEC C",       "LD C,$%02X",    "RRCA",        "STOP",          "LD DE,$%04X",
    "LD [DE],A",     "INC DE",      "INC D",         "DEC D",       "LD D,$%02X",    "RLA",
    "JR %+d",        "ADD HL,DE",   "LD A,[DE]",     "DEC DE",      "INC E",         "DEC E",
    "LD E,$%02X",    "RRA",         "JR NZ,%+d",     "LD HL,$%04X", "LD [HL+],A",    "INC HL",
    "INC H",         "DEC H",       "LD H,$%02X",    "DAA",         "JR Z,%+d",      "ADD HL,HL",
    "LD A,[HL+]",    "DEC HL",      "INC L",         "DEC L",       "LD L,$%02X",    "CPL",
    "JR NC,%+d",     "LD SP,$%04X", "LD [HL-],A",    "INC SP",      "INC [HL]",      "DEC [HL]",
    "LD [HL],$%02X", "SCF",         "JR C,%+d",      "ADD HL,SP",   "LD A,[HL-]",    "DEC SP",
    "INC A",         "DEC A",       "LD A,$%02X",    "CCF",         "LD B,B",        "LD B,C",
    "LD B,D",        "LD B,E",      "LD B,H",        "LD B,L",      "LD B,[HL]",     "LD B,A",
    "LD C,B",        "LD C,C",      "LD C,D",        "LD C,E",      "LD C,H",        "LD C,L",
    "LD C,[HL]",     "LD C,A",      "LD D,B",        "LD D,C",      "LD D,D",        "LD D,E",
    "LD D,H",        "LD D,L",      "LD D,[HL]",     "LD D,A",      "LD E,B",        "LD E,C",
    "LD E,D",        "LD E,E",      "LD E,H",        "LD E,L",      "LD E,[HL]",     "LD E,A",
    "LD H,B",        "LD H,C",      "LD H,D",        "LD H,E",      "LD H,H",        "LD H,L",
    "LD H,[HL]",     "LD H,A",      "LD L,B",        "LD L,C",      "LD L,D",        "LD L,E",
    "LD L,H",        "LD L,L",      "LD L,[HL]",     "LD L,A",      "LD [HL],B",     "LD [HL],C",
    "LD [HL],D",     "LD [HL],E",   "LD [HL],H",     "LD [HL],L",   "HALT",          "LD [HL],A",
    "LD A,B",        "LD A,C",      "LD A,D",        "LD A,E",      "LD A,H",        "LD A,L",
    "LD A,[HL]",     "LD A,A",      "ADD A,B",       "ADD A,C",     "ADD A,D",       "ADD A,E",
    "ADD A,H",       "ADD A,L",     "ADD A,[HL]",    "ADD A,A",     "ADC A,B",       "ADC A,C",
    "ADC A,D",       "ADC A,E",     "ADC A,H",       "ADC A,L",     "ADC A,[HL]",    "ADC A,A",
    "SUB A,B",       "SUB A,C",     "SUB A,D",       "SUB A,E",     "SUB A,H",       "SUB A,L",
    "SUB A,[HL]",    "SUB A,A",     "SBC A,B",       "SBC A,C",     "SBC A,D",       "SBC A,E",
    "SBC A,H",       "SBC A,L",     "SBC A,[HL]",    "SBC A,A",     "AND B",         "AND C",
    "AND D",         "AND E",       "AND H",         "AND L",       "AND [HL]",      "AND A",
    "XOR B",         "XOR C",       "XOR D",         "XOR E",       "XOR H",         "XOR L",
    "XOR [HL]",      "XOR A",       "OR B",          "OR C",        "OR D",          "OR E",
    "OR H",          "OR L",        "OR [HL]",       "OR A",        "CP B",          "CP C",
    "CP D",          "CP E",        "CP H",          "CP L",        "CP [HL]",       "CP A",
    "RET NZ",        "POP BC",      "JP NZ,$%04X",   "JP $%04X",    "CALL NZ,$%04X", "PUSH BC",
    "ADD A,$%02X",   "RST 00",      "RET Z",         "RET",         "JP Z,$%04X",    "ERR CB",
    "CALL Z,$%04X",  "CALL $%04X",  "ADC A,$%02X",   "RST 08",      "RET NC",        "POP DE",
    "JP NC,$%04X",   "ERR D3",      "CALL NC,$%04X", "PUSH DE",     "SUB A,$%02X",   "RST 10",
    "RET C",         "RETI",        "JP C,$%04X",    "ERR DB",      "CALL C,$%04X",  "ERR DD",
    "SBC A,$%02X",   "RST 18",      "LDH [$%02X],A", "POP HL",      "LDH [C],A",     "DBG",
    "ERR E4",        "PUSH HL",     "AND $%02X",     "RST 20",      "ADD SP %+d",    "JP HL",
    "LD [$%04X],A",  "ERR EB",      "ERR EC",        "ERR ED",      "XOR $%02X",     "RST 28",
    "LDH A,[$%02X]", "POP AF",      "LDH A,[C]",     "DI",          "ERR F4",        "PUSH AF",
    "OR $%02X",      "RST 30",      "LD HL,SP%+d",   "LD SP,HL",    "LD A,[$%04X]",  "EI",
    "ERR FC",        "ERR FD",      "CP $%02X",      "RST 38"};

const char *const CB_OP_NAMES[] = {
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
    "SET 7,B", "SET 7,C", "SET 7,D", "SET 7,E", "SET 7,H", "SET 7,L", "SET 7,[HL]", "SET 7,A"};

static inline void cpu_set_reg(struct CPU *self, u8 n, u8 val) {
    switch (n & 0x07) {
        case 0:
            self->B = val;
            break;
        case 1:
            self->C = val;
            break;
        case 2:
            self->D = val;
            break;
        case 3:
            self->E = val;
            break;
        case 4:
            self->H = val;
            break;
        case 5:
            self->L = val;
            break;
        case 6:
            ram_set(self->ram, self->HL, val);
            break;
        case 7:
            self->A = val;
            break;
        default:
            printf("Invalid register %d\n", n);
    }
}

static inline u8 cpu_get_reg(struct CPU *self, u8 n) {
    switch (n & 0x07) {
        case 0:
            return self->B;
            break;
        case 1:
            return self->C;
            break;
        case 2:
            return self->D;
            break;
        case 3:
            return self->E;
            break;
        case 4:
            return self->H;
            break;
        case 5:
            return self->L;
            break;
        case 6:
            return ram_get(self->ram, self->HL);
            break;
        case 7:
            return self->A;
            break;
        default:
            printf("Invalid register %d\n", n);
            return 0;
    }
}

static inline void cpu_push(struct CPU *self, u16 val) {
    ram_set(self->ram, self->SP - 1, ((val & 0xFF00) >> 8) & 0xFF);
    ram_set(self->ram, self->SP - 2, val & 0xFF);
    self->SP -= 2;
}

static inline u16 cpu_pop(struct CPU *self) {
    u16 val = (ram_get(self->ram, self->SP + 1) << 8) | ram_get(self->ram, self->SP);
    self->SP += 2;
    return val;
}

static inline void cpu_xor(struct CPU *self, u8 val) {
    self->A ^= val;

    self->FLAG_Z = self->A == 0;
    self->FLAG_N = false;
    self->FLAG_H = false;
    self->FLAG_C = false;
}

static inline void cpu_or(struct CPU *self, u8 val) {
    self->A |= val;

    self->FLAG_Z = self->A == 0;
    self->FLAG_N = false;
    self->FLAG_H = false;
    self->FLAG_C = false;
}

static inline void cpu_and(struct CPU *self, u8 val) {
    self->A &= val;

    self->FLAG_Z = self->A == 0;
    self->FLAG_N = false;
    self->FLAG_H = true;
    self->FLAG_C = false;
}

static inline void cpu_cp(struct CPU *self, u8 val) {
    self->FLAG_Z = self->A == val;
    self->FLAG_N = true;
    self->FLAG_H = (self->A & 0x0F) < (val & 0x0F);
    self->FLAG_C = self->A < val;
}

static inline void cpu_add(struct CPU *self, u8 val) {
    self->FLAG_C = self->A + val > 0xFF;
    self->FLAG_H = (self->A & 0x0F) + (val & 0x0F) > 0x0F;
    self->FLAG_N = false;
    self->A += val;
    self->FLAG_Z = self->A == 0;
}

static inline void cpu_adc(struct CPU *self, u8 val) {
    int carry = self->FLAG_C ? 1 : 0;
    self->FLAG_C = self->A + val + carry > 0xFF;
    self->FLAG_H = (self->A & 0x0F) + (val & 0x0F) + carry > 0x0F;
    self->FLAG_N = false;
    self->A += val + carry;
    self->FLAG_Z = self->A == 0;
}

static inline void cpu_sub(struct CPU *self, u8 val) {
    self->FLAG_C = self->A < val;
    self->FLAG_H = (self->A & 0x0F) < (val & 0x0F);
    self->A -= val;
    self->FLAG_Z = self->A == 0;
    self->FLAG_N = true;
}

static inline void cpu_sbc(struct CPU *self, u8 val) {
    u8 carry = self->FLAG_C ? 1 : 0;
    i16 res = self->A - val - carry;
    self->FLAG_H = ((self->A ^ val ^ (res & 0xff)) & (1 << 4)) != 0;
    self->FLAG_C = res < 0;
    self->A -= val + carry;
    self->FLAG_Z = self->A == 0;
    self->FLAG_N = true;
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
static inline void cpu_tick_cb(struct CPU *self, u8 op) {
    u8 val, bit;
    bool orig_c;

    val = cpu_get_reg(self, op);
    switch (op & 0xF8) {
        // RLC
        case 0x00 ... 0x07:
            self->FLAG_C = (val & (1 << 7)) != 0;
            val <<= 1;
            if (self->FLAG_C)
                val |= (1 << 0);
            self->FLAG_N = false;
            self->FLAG_H = false;
            self->FLAG_Z = val == 0;
            break;

            // RRC
        case 0x08 ... 0x0F:
            self->FLAG_C = (val & (1 << 0)) != 0;
            val >>= 1;
            if (self->FLAG_C)
                val |= (1 << 7);
            self->FLAG_N = false;
            self->FLAG_H = false;
            self->FLAG_Z = val == 0;
            break;

            // RL
        case 0x10 ... 0x17:
            orig_c = self->FLAG_C;
            self->FLAG_C = (val & (1 << 7)) != 0;
            val <<= 1;
            if (orig_c)
                val |= (1 << 0);
            self->FLAG_N = false;
            self->FLAG_H = false;
            self->FLAG_Z = val == 0;
            break;

            // RR
        case 0x18 ... 0x1F:
            orig_c = self->FLAG_C;
            self->FLAG_C = (val & (1 << 0)) != 0;
            val >>= 1;
            if (orig_c)
                val |= (1 << 7);
            self->FLAG_N = false;
            self->FLAG_H = false;
            self->FLAG_Z = val == 0;
            break;

            // SLA
        case 0x20 ... 0x27:
            self->FLAG_C = (val & (1 << 7)) != 0;
            val <<= 1;
            val &= 0xFF;
            self->FLAG_N = false;
            self->FLAG_H = false;
            self->FLAG_Z = val == 0;
            break;

            // SRA
        case 0x28 ... 0x2F:
            self->FLAG_C = (val & (1 << 0)) != 0;
            val >>= 1;
            if (val & (1 << 6))
                val |= (1 << 7);
            self->FLAG_N = false;
            self->FLAG_H = false;
            self->FLAG_Z = val == 0;
            break;

            // SWAP
        case 0x30 ... 0x37:
            val = ((val & 0xF0) >> 4) | ((val & 0x0F) << 4);
            self->FLAG_C = false;
            self->FLAG_N = false;
            self->FLAG_H = false;
            self->FLAG_Z = val == 0;
            break;

            // SRL
        case 0x38 ... 0x3F:
            self->FLAG_C = (val & (1 << 0)) != 0;
            val >>= 1;
            self->FLAG_N = false;
            self->FLAG_H = false;
            self->FLAG_Z = val == 0;
            break;

            // BIT
        case 0x40 ... 0x7F:
            bit = (op & 0b00111000) >> 3;
            self->FLAG_Z = (val & (1 << bit)) == 0;
            self->FLAG_N = false;
            self->FLAG_H = true;
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
        default:
            invalid_opcode_err(op);
            break;
    }
    cpu_set_reg(self, op, val);
}

/**
 * Execute a normal instruction (everything except for those
 * prefixed with 0xCB)
 */
static inline void cpu_tick_main(struct CPU *self, u8 op, union oparg arg) {
    // Load args

    // Execute
    u8 val = 0, carry = 0;
    u16 val16 = 0;
    switch (op) {
        // clang-format off
        case 0x00: /* NOP */; break;
        case 0x01: self->BC = arg.as_u16; break;
        case 0x02: ram_set(self->ram, self->BC, self->A); break;
        case 0x03: self->BC++; break;
        case 0x08:
            ram_set(self->ram, arg.as_u16+1, ((self->SP >> 8) & 0xFF));
            ram_set(self->ram, arg.as_u16, (self->SP & 0xFF));
            break;  // how does self fit?
        case 0x0A: self->A = ram_get(self->ram, self->BC); break;
        case 0x0B: self->BC--; break;

        case 0x10: self->stop = true; break;
        case 0x11: self->DE = arg.as_u16; break;
        case 0x12: ram_set(self->ram, self->DE, self->A); break;
        case 0x13: self->DE++; break;
        case 0x18: self->PC += arg.as_i8; break;
        case 0x1A: self->A = ram_get(self->ram, self->DE); break;
        case 0x1B: self->DE--; break;

        case 0x20: if(!self->FLAG_Z) self->PC += arg.as_i8; break;
        case 0x21: self->HL = arg.as_u16; break;
        case 0x22: ram_set(self->ram, self->HL++, self->A); break;
        case 0x23: self->HL++; break;
        case 0x27:
            val16 = self->A;
            if(self->FLAG_N == 0) {
                if (self->FLAG_H || (val16 & 0x0F) > 9) val16 += 6;
                if (self->FLAG_C || val16 > 0x9F) val16 += 0x60;
            }
            else {
                if(self->FLAG_H) {
                    val16 -= 6;
                    if (self->FLAG_C == 0) val16 &= 0xFF;
                }
                if(self->FLAG_C) val16 -= 0x60;
            }
            self->FLAG_H = false;
            if(val16 & 0x100) self->FLAG_C = true;
            self->A = val16 & 0xFF;
            self->FLAG_Z = self->A == 0;
            break;
        case 0x28: if(self->FLAG_Z) self->PC += arg.as_i8; break;
        case 0x2A: self->A = ram_get(self->ram, self->HL++); break;
        case 0x2B: self->HL--; break;
        case 0x2F: self->A ^= 0xFF; self->FLAG_N = true; self->FLAG_H = true; break;

        case 0x30: if(!self->FLAG_C) self->PC += arg.as_i8; break;
        case 0x31: self->SP = arg.as_u16; break;
        case 0x32: ram_set(self->ram, self->HL--, self->A); break;
        case 0x33: self->SP++; break;
        case 0x37: self->FLAG_N = false; self->FLAG_H = false; self->FLAG_C = true; break;
        case 0x38: if(self->FLAG_C) self->PC += arg.as_i8; break;
        case 0x3A: self->A = ram_get(self->ram, self->HL--); break;
        case 0x3B: self->SP--; break;
        case 0x3F: self->FLAG_C = !self->FLAG_C; self->FLAG_N = false; self->FLAG_H = false; break;

        case 0x04: case 0x0C: // INC r
        case 0x14: case 0x1C:
        case 0x24: case 0x2C:
        case 0x34: case 0x3C:
            val = cpu_get_reg(self, (op-0x04)/8);
            self->FLAG_H = (val & 0x0F) == 0x0F;
            val++;
            self->FLAG_Z = val == 0;
            self->FLAG_N = false;
            cpu_set_reg(self, (op-0x04)/8, val);
            break;

        case 0x05: case 0x0D: // DEC r
        case 0x15: case 0x1D:
        case 0x25: case 0x2D:
        case 0x35: case 0x3D:
            val = cpu_get_reg(self, (op-0x05)/8);
            val--;
            self->FLAG_H = (val & 0x0F) == 0x0F;
            self->FLAG_Z = val == 0;
            self->FLAG_N = true;
            cpu_set_reg(self, (op-0x05)/8, val);
            break;

        case 0x06: case 0x0E: // LD r,n
        case 0x16: case 0x1E:
        case 0x26: case 0x2E:
        case 0x36: case 0x3E:
            cpu_set_reg(self, (op-0x06)/8, arg.as_u8);
            break;

        case 0x07: // RCLA
        case 0x17: // RLA
        case 0x0F: // RRCA
        case 0x1F: // RRA
            carry = self->FLAG_C ? 1 : 0;
            if(op == 0x07) { // RCLA
                self->FLAG_C = (self->A & (1 << 7)) != 0;
                self->A = (self->A << 1) | (self->A >> 7);
            }
            if(op == 0x17) { // RLA
                self->FLAG_C = (self->A & (1 << 7)) != 0;
                self->A = (self->A << 1) | carry;
            }
            if(op == 0x0F) { // RRCA
                self->FLAG_C = (self->A & (1 << 0)) != 0;
                self->A = (self->A >> 1) | (self->A << 7);
            }
            if(op == 0x1F) { // RRA
                self->FLAG_C = (self->A & (1 << 0)) != 0;
                self->A = (self->A >> 1) | (carry << 7);
            }
            self->FLAG_N = false;
            self->FLAG_H = false;
            self->FLAG_Z = false;
            break;

        case 0x09: // ADD HL,rr
        case 0x19:
        case 0x29:
        case 0x39:
            if(op == 0x09) val16 = self->BC;
            if(op == 0x19) val16 = self->DE;
            if(op == 0x29) val16 = self->HL;
            if(op == 0x39) val16 = self->SP;
            self->FLAG_H = ((self->HL & 0x0FFF) + (val16 & 0x0FFF) > 0x0FFF);
            self->FLAG_C = (self->HL + val16 > 0xFFFF);
            self->HL += val16;
            self->FLAG_N = false;
            break;

        case 0x40 ... 0x7F: // LD r,r
            if(op == 0x76) {
                // FIXME: weird timing side effects
                self->halt = true;
                break;
            }
            cpu_set_reg(self, (op - 0x40)>>3, cpu_get_reg(self, op - 0x40));
            break;

        case 0x80 ... 0x87: cpu_add(self, cpu_get_reg(self, op)); break;
        case 0x88 ... 0x8F: cpu_adc(self, cpu_get_reg(self, op)); break;
        case 0x90 ... 0x97: cpu_sub(self, cpu_get_reg(self, op)); break;
        case 0x98 ... 0x9F: cpu_sbc(self, cpu_get_reg(self, op)); break;
        case 0xA0 ... 0xA7: cpu_and(self, cpu_get_reg(self, op)); break;
        case 0xA8 ... 0xAF: cpu_xor(self, cpu_get_reg(self, op)); break;
        case 0xB0 ... 0xB7: cpu_or(self, cpu_get_reg(self, op)); break;
        case 0xB8 ... 0xBF: cpu_cp(self, cpu_get_reg(self, op)); break;

        case 0xC0: if(!self->FLAG_Z) self->PC = cpu_pop(self); break;
        case 0xC1: self->BC = cpu_pop(self); break;
        case 0xC2: if(!self->FLAG_Z) self->PC = arg.as_u16; break;
        case 0xC3: self->PC = arg.as_u16; break;
        case 0xC4: if(!self->FLAG_Z) {cpu_push(self, self->PC); self->PC = arg.as_u16;} break;
        case 0xC5: cpu_push(self, self->BC); break;
        case 0xC6: cpu_add(self, arg.as_u8); break;
        case 0xC7: cpu_push(self, self->PC); self->PC = 0x00; break;
        case 0xC8: if(self->FLAG_Z) self->PC = cpu_pop(self); break;
        case 0xC9: self->PC = cpu_pop(self); break;
        case 0xCA: if(self->FLAG_Z) self->PC = arg.as_u16; break;
            // case 0xCB: break;
        case 0xCC: if(self->FLAG_Z) {cpu_push(self, self->PC); self->PC = arg.as_u16;} break;
        case 0xCD: cpu_push(self, self->PC); self->PC = arg.as_u16; break;
        case 0xCE: cpu_adc(self, arg.as_u8); break;
        case 0xCF: cpu_push(self, self->PC); self->PC = 0x08; break;

        case 0xD0: if(!self->FLAG_C) self->PC = cpu_pop(self); break;
        case 0xD1: self->DE = cpu_pop(self); break;
        case 0xD2: if(!self->FLAG_C) self->PC = arg.as_u16; break;
            // case 0xD3: break;
        case 0xD4: if(!self->FLAG_C) {cpu_push(self, self->PC); self->PC = arg.as_u16;} break;
        case 0xD5: cpu_push(self, self->DE); break;
        case 0xD6: cpu_sub(self, arg.as_u8); break;
        case 0xD7: cpu_push(self, self->PC); self->PC = 0x10; break;
        case 0xD8: if(self->FLAG_C) self->PC = cpu_pop(self); break;
        case 0xD9: self->PC = cpu_pop(self); self->interrupts = true; break;
        case 0xDA: if(self->FLAG_C) self->PC = arg.as_u16; break;
            // case 0xDB: break;
        case 0xDC: if(self->FLAG_C) {cpu_push(self, self->PC); self->PC = arg.as_u16;} break;
            // case 0xDD: break;
        case 0xDE: cpu_sbc(self, arg.as_u8); break;
        case 0xDF: cpu_push(self, self->PC); self->PC = 0x18; break;

        case 0xE0: ram_set(self->ram, 0xFF00 + arg.as_u8, self->A); if(arg.as_u8 == 0x01) {putchar(self->A);}; break;
        case 0xE1: self->HL = cpu_pop(self); break;
        case 0xE2: ram_set(self->ram, 0xFF00 + self->C, self->A); if(self->C == 0x01) {putchar(self->A);}; break;
            // case 0xE3: break;
            // case 0xE4: break;
        case 0xE5: cpu_push(self, self->HL); break;
        case 0xE6: cpu_and(self, arg.as_u8); break;
        case 0xE7: cpu_push(self, self->PC); self->PC = 0x20; break;
        case 0xE8:
            val16 = self->SP + arg.as_i8;
            //self->FLAG_H = ((self->SP & 0x0FFF) + (arg.as_i8 & 0x0FFF) > 0x0FFF);
            //self->FLAG_C = (self->SP + arg.as_i8 > 0xFFFF);
            self->FLAG_H = ((self->SP ^ arg.as_i8 ^ val16) & 0x10 ? true : false);
            self->FLAG_C = ((self->SP ^ arg.as_i8 ^ val16) & 0x100 ? true : false);
            self->SP += arg.as_i8;
            self->FLAG_Z = false;
            self->FLAG_N = false;
            break;
        case 0xE9: self->PC = self->HL; break;
        case 0xEA: ram_set(self->ram, arg.as_u16, self->A); break;
            // case 0xEB: break;
            // case 0xEC: break;
            // case 0xED: break;
        case 0xEE: cpu_xor(self, arg.as_u8); break;
        case 0xEF: cpu_push(self, self->PC); self->PC = 0x28; break;

        case 0xF0: self->A = ram_get(self->ram, 0xFF00 + arg.as_u8); break;
        case 0xF1: self->AF = (cpu_pop(self) & 0xFFF0); break;
        case 0xF2: self->A = ram_get(self->ram, 0xFF00 + self->C); break;
        case 0xF3: self->interrupts = false; break;
            // case 0xF4: break;
        case 0xF5: cpu_push(self, self->AF); break;
        case 0xF6: cpu_or(self, arg.as_u8); break;
        case 0xF7: cpu_push(self, self->PC); self->PC = 0x30; break;
        case 0xF8:
            if(arg.as_i8 >= 0) {
                self->FLAG_C = ((self->SP & 0xFF) + (arg.as_i8 & 0xFF)) > 0xFF;
                self->FLAG_H = ((self->SP & 0x0F) + (arg.as_i8 & 0x0F)) > 0x0F;
            } else {
                self->FLAG_C = ((self->SP + arg.as_i8) & 0xFF) <= (self->SP & 0xFF);
                self->FLAG_H = ((self->SP + arg.as_i8) & 0x0F) <= (self->SP & 0x0F);
            }
            // self->FLAG_H = ((((self->SP & 0x0f) + (arg.as_u8 & 0x0f)) & 0x10) != 0);
            // self->FLAG_C = ((((self->SP & 0xff) + (arg.as_u8 & 0xff)) & 0x100) != 0);
            self->HL = self->SP + arg.as_i8;
            self->FLAG_Z = false;
            self->FLAG_N = false;
            break;
        case 0xF9: self->SP = self->HL; break;
        case 0xFA: self->A = ram_get(self->ram, arg.as_u16); break;
        case 0xFB: self->interrupts = true; break;
        case 0xFC: unit_test_passed(); // unofficial
        case 0xFD: unit_test_failed(); // unofficial
        case 0xFE: cpu_cp(self, arg.as_u8); break;
        case 0xFF: cpu_push(self, self->PC); self->PC = 0x38; break;

            // missing ops
        default: invalid_opcode_err(op);
            // clang-format on
    }
}

static void cpu_dump_regs(struct CPU *self) {
    // stack
    u16 sp_val = ram_get(self->ram, self->SP) | ram_get(self->ram, self->SP + 1) << 8;

    // interrupts
    u8 IE = ram_get(self->ram, MEM_IE);
    u8 IF = ram_get(self->ram, MEM_IF);
    char z = 'z' ^ ((self->F >> 7) & 1) << 5;
    char n = 'n' ^ ((self->F >> 6) & 1) << 5;
    char h = 'h' ^ ((self->F >> 5) & 1) << 5;
    char c = 'c' ^ ((self->F >> 4) & 1) << 5;
    char v = (IE >> 0) & 1 ? 'v' ^ ((IF >> 0) & 1) << 5 : '_';
    char l = (IE >> 1) & 1 ? 'l' ^ ((IF >> 1) & 1) << 5 : '_';
    char t = (IE >> 2) & 1 ? 't' ^ ((IF >> 2) & 1) << 5 : '_';
    char s = (IE >> 3) & 1 ? 's' ^ ((IF >> 3) & 1) << 5 : '_';
    char j = (IE >> 4) & 1 ? 'j' ^ ((IF >> 4) & 1) << 5 : '_';

    // opcode & args
    u8 op = ram_get(self->ram, self->PC);
    char op_str[16] = "";
    if (op == 0xCB) {
        op = ram_get(self->ram, self->PC + 1);
        snprintf(op_str, 16, "%s", CB_OP_NAMES[op]);
    } else {
        if (OP_ARG_TYPES[op] == 0)
            snprintf(op_str, 16, "%s", OP_NAMES[op]);
        if (OP_ARG_TYPES[op] == 1)
            snprintf(op_str, 16, OP_NAMES[op], ram_get(self->ram, self->PC + 1));
        if (OP_ARG_TYPES[op] == 2)
            snprintf(
                op_str, 16, OP_NAMES[op], ram_get(self->ram, self->PC + 1) | ram_get(self->ram, self->PC + 2) << 8
            );
        if (OP_ARG_TYPES[op] == 3)
            snprintf(op_str, 16, OP_NAMES[op], (i8) ram_get(self->ram, self->PC + 1));
    }

    // print
    // clang-format off
    printf(
        "%04X %04X %04X %04X : %04X = %04X : %c%c%c%c : %c%c%c%c%c : %04X = %02X : %s\n",
        self->AF, self->BC, self->DE, self->HL,
        self->SP, sp_val,
        z, n, h, c,
        v, l, t, s, j,
        self->PC, op, op_str
    );
    // clang-format on
}

/**
 * Pick an instruction from RAM as pointed to by the
 * Program Counter register; if the instruction takes
 * an argument then pick that too; then execute it.
 */
static inline void cpu_tick_instructions(struct CPU *self) {
    // if the previous instruction was large, let's not run any
    // more instructions until other subsystems have caught up
    if (self->owed_cycles) {
        self->owed_cycles--;
        return;
    }

    if (self->debug) {
        cpu_dump_regs(self);
    }

    u8 op = ram_get(self->ram, self->PC);
    if (op == 0xCB) {
        op = ram_get(self->ram, self->PC + 1);
        self->PC += 2;
        cpu_tick_cb(self, op);
        self->owed_cycles = OP_CB_CYCLES[op];
    } else {
        union oparg arg;
        arg.as_u16 = 0xCA75;
        u8 arg_len = OP_ARG_BYTES[OP_ARG_TYPES[op]];
        if (arg_len == 1) {
            arg.as_u8 = ram_get(self->ram, self->PC + 1);
        }
        if (arg_len == 2) {
            u16 low = ram_get(self->ram, self->PC + 1);
            u16 high = ram_get(self->ram, self->PC + 2);
            arg.as_u16 = high << 8 | low;
        }
        self->PC += 1 + arg_len;
        cpu_tick_main(self, op, arg);
        self->owed_cycles = OP_CYCLES[op];
    }
    if (self->owed_cycles > 0) {
        self->owed_cycles -= 1; // HALT has cycles=0
    }
}

static inline bool cpu_check_interrupt(struct CPU *self, u8 queue, u8 i, u16 handler) {
    if (queue & i) {
        // TODO: wait two cycles
        // TODO: push16(PC) should also take two cycles
        // TODO: one more cycle to store new PC
        cpu_push(self, self->PC);
        self->PC = handler;
        ram_set(self->ram, MEM_IF, ram_get(self->ram, MEM_IF) & ~i);
        return true;
    }
    return false;
}

/**
 * Compare Interrupt Enabled and Interrupt Flag registers - if
 * there are any interrupts which are both enabled and flagged,
 * clear the flag and call the handler for the first of them.
 */
static inline void cpu_tick_interrupts(struct CPU *self) {
    u8 queue = ram_get(self->ram, MEM_IE) & ram_get(self->ram, MEM_IF);
    if (self->interrupts && queue) {
        if (self->debug) {
            printf("Handling interrupts: %02X & %02X\n", ram_get(self->ram, MEM_IE), ram_get(self->ram, MEM_IF));
        }
        self->interrupts = false; // no nested interrupts, RETI will re-enable
        cpu_check_interrupt(self, queue, INTERRUPT_VBLANK, MEM_VBLANK_HANDLER) ||
            cpu_check_interrupt(self, queue, INTERRUPT_STAT, MEM_LCD_HANDLER) ||
            cpu_check_interrupt(self, queue, INTERRUPT_TIMER, MEM_TIMER_HANDLER) ||
            cpu_check_interrupt(self, queue, INTERRUPT_SERIAL, MEM_SERIAL_HANDLER) ||
            cpu_check_interrupt(self, queue, INTERRUPT_JOYPAD, MEM_JOYPAD_HANDLER);
    }
}

/**
 * Increment the timer registers, and send an interrupt
 * when TIMA wraps around.
 */
static inline void cpu_tick_clock(struct CPU *self) {
    self->cycle++;

    // TODO: writing any value to MEM_DIV should reset it to 0x00
    // increment at 16384Hz (each 64 cycles?)
    if (self->cycle % 64 == 0)
        ram_set(self->ram, MEM_DIV, ram_get(self->ram, MEM_DIV) + 1);

    if (ram_get(self->ram, MEM_TAC) & (1 << 2)) { // timer enable
        u16 speeds[] = {256, 4, 16, 64};          // increment per X cycles
        u16 speed = speeds[ram_get(self->ram, MEM_TAC) & 0x03];
        if (self->cycle % speed == 0) {
            if (ram_get(self->ram, MEM_TIMA) == 0xFF) {
                ram_set(self->ram, MEM_TIMA, ram_get(self->ram, MEM_TMA)); // if timer overflows, load base
                cpu_interrupt(self, INTERRUPT_TIMER);
            }
            ram_set(self->ram, MEM_TIMA, ram_get(self->ram, MEM_TIMA) + 1);
        }
    }
}

/**
 * If there is a non-zero value in ram[MEM_DMA], eg 0x42, then
 * we should copy memory from eg 0x4200 to OAM space.
 */
static inline void cpu_tick_dma(struct CPU *self) {
    // TODO: DMA should take 26 cycles, during which main RAM is inaccessible
    if (ram_get(self->ram, MEM_DMA)) {
        u16 dma_src = ram_get(self->ram, MEM_DMA) << 8;
        for (int i = 0; i < 0xA0; i++) {
            ram_set(self->ram, MEM_OAM_BASE + i, ram_get(self->ram, dma_src + i));
        }
        ram_set(self->ram, MEM_DMA, 0x00);
    }
}

/**
 * Initialise registers and RAM, map the first banks of Cart
 * code into the RAM address space.
 */
void cpu_ctor(struct CPU *self, struct RAM *ram, bool debug) {
    *self = (struct CPU){
        .ram = ram,
        .debug = debug,
        .interrupts = false,
        .AF = 0x0000,
        .BC = 0x0000,
        .DE = 0x0000,
        .HL = 0x0000,
        .SP = 0x0000,
        .PC = 0x0000,
    };
}

void cpu_stop(struct CPU *cpu, bool stop) {
    cpu->stop = stop;
}

bool cpu_is_stopped(struct CPU *cpu) {
    return cpu->stop;
}

/**
 * Set a given interrupt bit - on the next tick, if the interrupt
 * handler for this interrupt is enabled (and interrupts in general
 * are enabled), then the interrupt handler will be called.
 */
void cpu_interrupt(struct CPU *self, enum Interrupt i) {
    ram_set(self->ram, MEM_IF, ram_get(self->ram, MEM_IF) | i);
    self->halt = false; // interrupts interrupt HALT state
}

void cpu_tick(struct CPU *self) {
    cpu_tick_dma(self);
    cpu_tick_clock(self);
    cpu_tick_interrupts(self);
    if (self->halt)
        return;
    if (self->stop)
        return;
    cpu_tick_instructions(self);
}
