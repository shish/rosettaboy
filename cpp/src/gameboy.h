#ifndef ROSETTABOY_GAMEBOY_H
#define ROSETTABOY_GAMEBOY_H

#include "apu.h"
#include "args.h"
#include "buttons.h"
#include "cart.h"
#include "clock.h"
#include "cpu.h"
#include "gpu.h"

class GameBoy {
private:
    Cart *cart = nullptr;
    RAM *ram = nullptr;
    CPU *cpu = nullptr;
    GPU *gpu = nullptr;
    Buttons *buttons = nullptr;
    Clock *clock = nullptr;

public:
    GameBoy(Args *args);
    void run();
    void tick();
};

#endif // ROSETTABOY_GAMEBOY_H
