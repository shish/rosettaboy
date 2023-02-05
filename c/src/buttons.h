#ifndef ROSETTABOY_BUTTONS_H
#define ROSETTABOY_BUTTONS_H

#include "consts.h"
#include <SDL2/SDL.h>

struct CPU;
struct RAM;

struct Buttons {
    u32 cycle;
    struct CPU *cpu;
    struct RAM *ram;
    bool up;
    bool down;
    bool left;
    bool right;
    bool a;
    bool b;
    bool start;
    bool select;
    bool turbo;
};

void buttons_ctor(struct Buttons *self, struct CPU *cpu, struct RAM *ram, bool headless);
void buttons_tick(struct Buttons *self);

#endif // ROSETTABOY_BUTTONS_H
