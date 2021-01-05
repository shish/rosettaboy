#include "clock.h"

Clock::Clock(Buttons *buttons, int profile, bool turbo, bool fps) {
    this->buttons = buttons;
    this->profile = profile;
    this->turbo = turbo;
    this->fps = fps;
    this->sleep_duration = 0;
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
            this->sleep_duration += sleep_for;
        }
        last_frame_start = SDL_GetTicks();

        // Print FPS once per second
        if (this->fps && this->frame % 60 == 0) {
            int t = SDL_GetTicks();
            float fps = 60000.0/(t - this->last_report);
            float busy = 1.0f - (this->sleep_duration/1000.0f);
            printf("%.1ffps %.1f%% busy\n", fps, busy * 100);
            this->sleep_duration = 0;
            this->last_report = t;
        }

        // Exit if we've hit the frame limit
        if(this->profile != 0 && this->frame > this->profile) {
            return false;
        }

        this->frame++;
    }
    
    return true;
}