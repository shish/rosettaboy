#ifndef SPIGOT_CLOCK_H
#define SPIGOT_CLOCK_H

#include <SDL2/SDL.h>
#include "buttons.h"
#include "consts.h"

class Clock {
private:
    int cycle=0;
    int frame=0;
    int last_frame_start = SDL_GetTicks();
    bool profile = false;
    bool turbo = false;
    Buttons *buttons = nullptr;
public:
    Clock(Buttons *buttons, bool profile, bool turbo);
    ~Clock();
    bool tick();
};

#endif //SPIGOT_CLOCK_H
