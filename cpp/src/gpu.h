#ifndef SPIGOT_GPU_H
#define SPIGOT_GPU_H

#include <SDL2/SDL.h>
#include "cpu.h"

struct Sprite {
    u8 y;
    u8 x;
    u8 tile_id;
    union {
        u8 flags;
        struct {
            unsigned char _empty:4;
            unsigned char palette:1;
            unsigned char x_flip:1;
            unsigned char y_flip:1;
            unsigned char behind:1;
        };
    };

    bool is_live();
};

class GPU {
private:
    bool debug;
    SDL_Window *window;
    SDL_Surface *buffer;
    SDL_Renderer *renderer;
    u32 colors[4];
    u32 bgp[4], obp0[4], obp1[4];
    int cycle;
    CPU *cpu;

public:
    GPU(CPU *cpu, bool headless, bool debug);
    ~GPU();
    bool tick();

private:
    bool draw_lcd();
    void update_palettes();
    void paint_tile(SDL_Surface *surf, i16 tile_id, SDL_Point *offset, u32 *palette, bool flip_x, bool flip_y);
};

#endif //SPIGOT_GPU_H
