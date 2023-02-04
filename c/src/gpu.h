#ifndef ROSETTABOY_GPU_H
#define ROSETTABOY_GPU_H

#include "consts.h"
#include <SDL2/SDL.h>
#include <stdbool.h>

struct GPU {
    struct CPU *cpu;
    struct RAM *ram;
    bool debug;
    SDL_Window *hw_window;
    SDL_Texture *hw_buffer;
    SDL_Renderer *hw_renderer;
    SDL_Surface *buffer;
    SDL_Renderer *renderer;
    SDL_Color colors[4];
    SDL_Color bgp[4];
    SDL_Color obp0[4];
    SDL_Color obp1[4];
    int cycle;
};

void gpu_ctor(struct GPU *self, struct CPU *cpu, struct RAM *ram, char *title, bool headless, bool debug);
void gpu_dtor(struct GPU *self);
void gpu_tick(struct GPU *self);

#endif // ROSETTABOY_GPU_H
