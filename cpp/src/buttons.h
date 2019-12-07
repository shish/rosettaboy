#ifndef SPIGOT_BUTTONS_H
#define SPIGOT_BUTTONS_H

#include <SDL2/SDL.h>
#include "cpu.h"
#include "consts.h"

class Buttons {
private:
    const u8 *pressed = nullptr;
    u32 cycle = 0;
    CPU *cpu = nullptr;

public:
    Buttons(CPU *cpu);
    bool tick();
    bool turbo = false;

private:
    bool handle_inputs();
    void update_buttons();
};

#endif //SPIGOT_BUTTONS_H
