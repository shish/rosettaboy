#ifndef SPIGOT_CPU_H
#define SPIGOT_CPU_H

#include <cstdint>

#include "cart.h"
#include "ram.h"

union oparg {
    u8 B;
    i8 b;
    u16 H;
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
    bool tick();
    void interrupt(Interrupt i);
    void dump_regs();

private:
    bool tick_debugger();
    void tick_dma();
    bool tick_clock();
    bool tick_interrupts();
    bool tick_instructions();
    void tick_main(u8 op);
    void tick_cb(u8 op);

    void _xor(u8 arg);
    void _or(u8 arg);
    void _and(u8 arg);
    void _cp(u8 arg);
    void _add(u8 arg);
    void _adc(u8 arg);
    void _sub(u8 arg);
    void _sbc(u8 arg);

    void push(u16 arg);
    u16 pop();

    u8 get_reg(int n);
    u8 set_reg(int n, u8 val);
};

#endif //SPIGOT_CPU_H
