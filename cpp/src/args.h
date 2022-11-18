#ifndef ROSETTABOY_ARGS_H
#define ROSETTABOY_ARGS_H

#include "_args.h"

class Args {
public:
    Args(int argc, char *argv[]);
    int exit_code = -1;
    bool headless;
    bool silent;
    bool debug_cpu;
    bool debug_gpu;
    bool debug_apu;
    bool debug_ram;
    int frames;
    int profile;
    bool turbo;
    std::string rom;
};

#endif // ROSETTABOY_ARGS_H
