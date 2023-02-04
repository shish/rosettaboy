#ifndef ROSETTABOY_CPU_H
#define ROSETTABOY_CPU_H

#include "consts.h"

struct RAM;

union oparg {
    u8 as_u8;   // B
    i8 as_i8;   // b
    u16 as_u16; // H
};

struct CPU {
    struct RAM *ram;
    bool stop;
    bool stepping;
    bool interrupts;
    bool halt;
    bool debug;
    int cycle;
    int owed_cycles;

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
};

void cpu_ctor(struct CPU *self, struct RAM *ram, bool debug);
void cpu_interrupt(struct CPU *cpu, enum Interrupt i);
void cpu_stop(struct CPU *cpu, bool stop);
bool cpu_is_stopped(struct CPU *cpu);
void cpu_tick(struct CPU *self);

#endif // ROSETTABOY_CPU_H
