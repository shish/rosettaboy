#include "clock.h"
#include "errors.h"

Clock::Clock(Buttons *buttons, int frames, int profile, bool turbo) {
    this->buttons = buttons;
    this->frames = frames;
    this->profile = profile;
    this->turbo = turbo;
}

void Clock::tick() {
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

        // Exit if we've hit the frame or time limit
        auto duration = (double)(last_frame_start - this->start) / 1000.0;
        if((this->frames != 0 && this->frame >= this->frames) || (this->profile != 0 && duration >= this->profile)) {
            throw new Timeout(this->frame, duration);
        }

        this->frame++;
    }
}