#ifndef SPIGOT_CLOCK_H
#define SPIGOT_CLOCK_H

#include <SDL2/SDL.h>
#include "buttons.h"
#include "consts.h"

class Clock {
private:
    Buttons *buttons = nullptr;
    int cycle = 0;
    int frame = 0;
    int last_frame_start = SDL_GetTicks();
    int start = SDL_GetTicks();
    int profile = 0;
    bool turbo = false;
public:
    Clock(Buttons *buttons, int profile, bool turbo);
    ~Clock();
    bool tick();
};

#endif //SPIGOT_CLOCK_H
