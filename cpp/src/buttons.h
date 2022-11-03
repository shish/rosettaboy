#ifndef ROSETTABOY_BUTTONS_H
#define ROSETTABOY_BUTTONS_H

#include <SDL2/SDL.h>

#include "consts.h"
#include "cpu.h"

namespace Joypad {
    const u8 MODE_BUTTONS = 1 << 5;
    const u8 MODE_DPAD = 1 << 4;
    const u8 DOWN = 1 << 3;
    const u8 START = 1 << 3;
    const u8 UP = 1 << 2;
    const u8 SELECT = 1 << 2;
    const u8 LEFT = 1 << 1;
    const u8 B = 1 << 1;
    const u8 RIGHT = 1 << 0;
    const u8 A = 1 << 0;
} // namespace Joypad

class Buttons {
private:
    u32 cycle = 0;
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
    Buttons(CPU *cpu, bool headless);
    void tick();
    bool turbo = false;

private:
    bool handle_inputs();
    void update_buttons();
};

#endif // ROSETTABOY_BUTTONS_H
