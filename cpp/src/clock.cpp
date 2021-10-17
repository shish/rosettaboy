#include "clock.h"

Clock::Clock(Buttons *buttons, int profile, bool turbo) {
    this->buttons = buttons;
    this->profile = profile;
    this->turbo = turbo;
}

bool Clock::tick() {
    this->cycle++;

    // Do a whole frame's worth of sleeping at the start of each frame
    if(this->cycle % 17556 == 20) {
        // Sleep if we have time left over
        u32 time_spent = (SDL_GetTicks() - last_frame_start);
        i32 sleep_for = (1000 / 60) - time_spent;
        if(sleep_for > 0 && !this->turbo && !this->buttons->turbo) {
            SDL_Delay(sleep_for);
        }
        last_frame_start = SDL_GetTicks();

        // Exit if we've hit the frame limit
        if(this->profile != 0 && this->frame > this->profile) {
            auto duration = (double)(SDL_GetTicks() - this->start) / 1000.0;
            printf("Emulated %d frames in %.2fs (%.2ffps)\n", this->profile, duration, this->profile / duration);
            return false;
        }

        this->frame++;
    }

    return true;
}