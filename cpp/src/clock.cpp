#include "clock.h"

Clock::Clock(Buttons *buttons, bool profile, bool turbo) {
    this->buttons = buttons;
    this->profile = profile;
    this->turbo = turbo;
}

bool Clock::tick() {
    u8 LX = cycle % 114;
    u8 LY = (cycle / 114) % 154;
    if(LX == 20 && LY == 0) {
        u32 time_spent = (SDL_GetTicks() - last_frame_start);
        i32 sleep_for = (1000 / 60) - time_spent;
        //printf("Frame took %d/%d ticks\n", time_spent, 1000/60);
        if(sleep_for > 0 && !this->turbo && !this->buttons->turbo) {
            SDL_Delay(sleep_for);
        }
        last_frame_start = SDL_GetTicks();
        frame++;
    }

    if(profile && frame > 60 * 10) return false;

    cycle++;

    return true;
}