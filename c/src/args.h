#ifndef ROSETTABOY_ARGS_H
#define ROSETTABOY_ARGS_H

#include "consts.h"

struct Args {
    int exit_code;
    bool headless;
    bool silent;
    bool debug_cpu;
    bool debug_gpu;
    bool debug_apu;
    bool debug_ram;
    int frames;
    int profile;
    bool turbo;
    const char *rom;
};

void parse_args(struct Args *args, int argc, char *argv[]);

#endif // ROSETTABOY_ARGS_H
