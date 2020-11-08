#ifndef SPIGOT_BUTTONS_H
#define SPIGOT_BUTTONS_H

#include <SDL2/SDL.h>
#include "cpu.h"
#include "consts.h"

class Buttons {
private:
    u32 cycle = 0;
    bool need_interrupt = false;
    CPU *cpu = nullptr;
    bool up = false;
    bool down = false;
    bool left = false;
    bool right = false;
    bool a = false;
    bool b = false;
    bool start = false;
    bool select = false;

public:
    Buttons(CPU *cpu);
    bool tick();
    bool turbo = false;

private:
    bool handle_inputs();
    void update_buttons();
};

#endif //SPIGOT_BUTTONS_H
