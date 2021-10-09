#ifndef SPIGOT_CLOCK_H
#define SPIGOT_CLOCK_H

#include <SDL2/SDL.h>
#include "buttons.h"
#include "consts.h"

class Clock {
private:
    int cycle = 0;
    int frame = 0;
    int last_frame_start = SDL_GetTicks();
    int last_report = SDL_GetTicks();
    int start = SDL_GetTicks();
    int sleep_duration = 0;
    int profile = 0;
    bool turbo = false;
    bool fps = false;
    Buttons *buttons = nullptr;
public:
    Clock(Buttons *buttons, int profile, bool turbo, bool fps);
    ~Clock();
    bool tick();
};

#endif //SPIGOT_CLOCK_H
