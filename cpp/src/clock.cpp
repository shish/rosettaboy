#include "clock.h"

Clock::Clock(Buttons *buttons, int profile, bool turbo) {
    this->buttons = buttons;
    this->profile = profile;
    this->turbo = turbo;
}

bool Clock::tick() {
    if(cycle > 70224) {
        cycle = 0;

        // Sleep if we have time left over
        u32 time_spent = (SDL_GetTicks() - last_frame_start);
        i32 sleep_for = (1000 / 60) - time_spent;
        if(sleep_for > 0 && !this->turbo && !this->buttons->turbo) {
            SDL_Delay(sleep_for);
        }
        last_frame_start = SDL_GetTicks();

        // Exit if we've hit the frame limit
        if(profile != 0 && frame > profile) {
            return false;
        }

        frame++;
    }
    cycle++;
    return true;
}