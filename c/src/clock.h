#ifndef ROSETTABOY_CLOCK_H
#define ROSETTABOY_CLOCK_H

#include "consts.h"

struct Buttons;

struct Clock {
    struct Buttons *buttons;
    int cycle;
    int frame;
    int last_frame_start;
    int start;
    int frames;
    int profile;
    bool turbo;
};

void clock_ctor(struct Clock *self, struct Buttons *buttons, int frames, int profile, bool turbo);
void clock_tick(struct Clock *self);

#endif // ROSETTABOY_CLOCK_H
