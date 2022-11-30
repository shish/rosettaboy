#ifndef ROSETTABOY_CPU_H
#define ROSETTABOY_CPU_H

#include <cstdint>

#include "cart.h"
#include "ram.h"

const u8 OP_CYCLES[] = {
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

const u8 OP_CB_CYCLES[] = {
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

const u8 OP_ARG_TYPES[] = {
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

const u8 OP_ARG_BYTES[] = {0, 1, 2, 1};

const std::string OP_NAMES[] = {
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

const std::string CB_OP_NAMES[] = {
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

union oparg {
    u8 as_u8;   // B
    i8 as_i8;   // b
    u16 as_u16; // H
};

class CPU {
public:
    RAM *ram;
    bool stop = false;
    bool stepping = false;

private:
    bool interrupts = true;
    bool halt = false;
    bool debug = true;
    int cycle = 0;
    int owed_cycles = 0;

public:
    union {
        u16 AF;
        struct {
            u8 F;
            u8 A;
        };
        struct {
            unsigned int _1 : 4;
            unsigned int FLAG_C : 1;
            unsigned int FLAG_H : 1;
            unsigned int FLAG_N : 1;
            unsigned int FLAG_Z : 1;
            unsigned int _2 : 8;
        };
    };
    union {
        u16 BC;
        struct {
            u8 C;
            u8 B;
        };
    };
    union {
        u16 DE;
        struct {
            u8 E;
            u8 D;
        };
    };
    union {
        u16 HL;
        struct {
            u8 L;
            u8 H;
        };
    };
    u16 SP;
    u16 PC;

public:
    CPU(RAM *ram, bool debug);
    void tick();
    void interrupt(Interrupt::Interrupt i);
    void dump_regs();

private:
    void tick_dma();
    void tick_clock();
    bool check_interrupt(u8 queue, u8 i, u16 handler);
    void tick_interrupts();
    void tick_instructions();
    void tick_main(u8 op, oparg arg);
    void tick_cb(u8 op);

    void _xor(u8 val);
    void _or(u8 val);
    void _and(u8 val);
    void _cp(u8 val);
    void _add(u8 val);
    void _adc(u8 val);
    void _sub(u8 val);
    void _sbc(u8 val);

    void push(u16 val);
    u16 pop();

    u8 get_reg(u8 n);
    void set_reg(u8 n, u8 val);
};

#endif // ROSETTABOY_CPU_H
