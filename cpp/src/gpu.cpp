#include <SDL2/SDL.h>

#include "consts.h"
#include "gpu.h"

u16 SCALE = 2;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
u32 rmask = 0xff000000;
u32 gmask = 0x00ff0000;
u32 bmask = 0x0000ff00;
u32 amask = 0x000000ff;
#else
u32 rmask = 0x000000ff;
u32 gmask = 0x0000ff00;
u32 bmask = 0x00ff0000;
u32 amask = 0xff000000;
#endif


GPU::GPU(CPU *cpu, bool headless, bool debug) {
    this->cpu = cpu;
    this->debug = debug;

    // Window
    int w=160, h=144;
    SDL_Init(SDL_INIT_EVERYTHING);
    if(this->debug) {
        w = 512;
        h = 256;
    }
    if(!headless) {
        this->window = SDL_CreateWindow(
                "Spigot",                  // window title
                SDL_WINDOWPOS_UNDEFINED,   // initial x position
                SDL_WINDOWPOS_UNDEFINED,   // initial y position
                w * SCALE,                 // width, in pixels
                h * SCALE,                 // height, in pixels
                SDL_WINDOW_ALLOW_HIGHDPI|SDL_WINDOW_RESIZABLE   // flags - see below
        );
    }
    this->buffer = SDL_CreateRGBSurface(0, w, h, 32, rmask, gmask, bmask, amask);
    this->renderer = SDL_CreateSoftwareRenderer(this->buffer);

    // Colors
    this->colors[0] = SDL_MapRGB(this->buffer->format, 0x9B, 0xBC, 0x0F);
    this->colors[1] = SDL_MapRGB(this->buffer->format, 0x8B, 0xAC, 0x0F);
    this->colors[2] = SDL_MapRGB(this->buffer->format, 0x30, 0x62, 0x30);
    this->colors[3] = SDL_MapRGB(this->buffer->format, 0x0F, 0x38, 0x0F);
    //printf("SDL_Init failed: %s\n", SDL_GetError());
};

GPU::~GPU() {
    SDL_FreeSurface(this->buffer);
    if(this->window) SDL_DestroyWindow(this->window);
    SDL_Quit();
}

bool GPU::tick() {
    // CPU STOP stops all LCD activity until a button is pressed
    if(this->cpu->stop) {
        return true;
    }

    u8 LX = cycle % 114;
    u8 LY = (cycle / 114) % 154;
    this->cpu->ram->set(IO_LY, LY);

    // LYC compare & interrupt
    if(this->cpu->ram->get(IO_LY) == cpu->ram->get(IO_LYC)) {
        if(this->cpu->ram->get(IO_STAT) & STAT_LYC_INTERRUPT) {
            this->cpu->interrupt(INT_STAT);
        }
        this->cpu->ram->_or(IO_STAT, STAT_LCY_EQUAL);
    }
    else {
        this->cpu->ram->_and(IO_STAT, ~STAT_LCY_EQUAL);
    }

    // Set mode
    if(LX == 0 && LY < 144) {
        this->cpu->ram->set(IO_STAT, (this->cpu->ram->get(IO_STAT) & ~STAT_MODE) | STAT_MODE_OAM);
        if(this->cpu->ram->get(IO_STAT) & STAT_OAM_INTERRUPT) {
            this->cpu->interrupt(INT_STAT);
        }
    }
    else if(LX == 20 && LY < 144) {
        this->cpu->ram->set(IO_STAT, (this->cpu->ram->get(IO_STAT) & ~STAT_MODE) | STAT_MODE_DRAWING);
        // TODO: really we should draw one line of pixels for each LY,
        // rather than the whole screen at LY == 0
        if(LY == 0) {
            if (!this->draw_lcd()) return false;
        }
    }
    else if(LX == 63 && LY < 144) {
        this->cpu->ram->set(IO_STAT, (this->cpu->ram->get(IO_STAT) & ~STAT_MODE) | STAT_MODE_HBLANK);
        if(this->cpu->ram->get(IO_STAT) & STAT_HBLANK_INTERRUPT) {
            this->cpu->interrupt(INT_STAT);
        }
    }
    else if(LX == 0 && LY == 144) {
        this->cpu->ram->set(IO_STAT, (this->cpu->ram->get(IO_STAT) & ~STAT_MODE) | STAT_MODE_VBLANK);
        if(this->cpu->ram->get(IO_STAT) & STAT_VBLANK_INTERRUPT) {
            this->cpu->interrupt(INT_STAT);
        }
        this->cpu->interrupt(INT_VBLANK);
    }

    this->cycle++;

    return true;
}

void GPU::update_palettes() {
    u8 raw_bgp = this->cpu->ram->get(IO_BGP);
    bgp[0] = this->colors[(raw_bgp >> 0) & 0x3];
    bgp[1] = this->colors[(raw_bgp >> 2) & 0x3];
    bgp[2] = this->colors[(raw_bgp >> 4) & 0x3];
    bgp[3] = this->colors[(raw_bgp >> 6) & 0x3];

    u8 raw_obp0 = this->cpu->ram->get(IO_OBP0);
    obp0[0] = this->colors[(raw_obp0 >> 0) & 0x3];
    obp0[1] = this->colors[(raw_obp0 >> 2) & 0x3];
    obp0[2] = this->colors[(raw_obp0 >> 4) & 0x3];
    obp0[3] = this->colors[(raw_obp0 >> 6) & 0x3];

    u8 raw_obp1 = this->cpu->ram->get(IO_OBP1);
    obp1[0] = this->colors[(raw_obp1 >> 0) & 0x3];
    obp1[1] = this->colors[(raw_obp1 >> 2) & 0x3];
    obp1[2] = this->colors[(raw_obp1 >> 4) & 0x3];
    obp1[3] = this->colors[(raw_obp1 >> 6) & 0x3];
}

bool GPU::draw_lcd() {
    this->update_palettes();

    u8 LCDC = this->cpu->ram->get(IO_LCDC);

    SDL_FillRect(this->buffer, nullptr, bgp[0]);

    // LCD enabled at all
    if (!(LCDC & LCDC_ENABLED)) {
        // When LCD is re-enabled, LY is 0
        // Does it become 0 as soon as disabled??
        this->cpu->ram->set(IO_LY, 0);
        if(!debug) return true;
    }

    // Tile data
    if(debug) {
        int tile_display_width = 32;
        for(u16 tile_id=0; tile_id < 384; tile_id++) {
            SDL_Point xy = {
                .x = 256 + (tile_id % tile_display_width) * 8,
                .y = (tile_id / tile_display_width) * 8,
            };
            this->paint_tile(this->buffer, tile_id, &xy, bgp, false, false);
        }
    }

    // Background tiles
    if (LCDC & LCDC_BG_WIN_ENABLED || debug) {
        u8 SCROLL_Y = this->cpu->ram->get(IO_SCY);
        u8 SCROLL_X = this->cpu->ram->get(IO_SCX);
        bool tile_offset = !(LCDC & LCDC_DATA_SRC);
        u16 background_map = (LCDC & LCDC_BG_MAP) ? BACKGROUND_MAP_1 : BACKGROUND_MAP_0;

        for (int tile_y = SCROLL_Y/8; tile_y < (debug ? 32 : 19) + SCROLL_Y/8; tile_y++) {
            for (int tile_x = SCROLL_X/8; tile_x < (debug ? 32 : 21) + SCROLL_X/8; tile_x++) {
                u16 tile_id = this->cpu->ram->get(background_map + (tile_y % 32) * 32 + (tile_x % 32));
                if (tile_offset && tile_id < 0x80) tile_id += 0x100;
                SDL_Point xy = {
                    .x = ((tile_x * 8 - SCROLL_X) + 8) % 256 - 8,
                    .y = ((tile_y * 8 - SCROLL_Y) + 8) % 256 - 8,
                };
                this->paint_tile(this->buffer, tile_id, &xy, bgp, false, false);
            }
        }

        // Background scroll border
        if(debug) {
            SDL_Rect rect = {.x=0, .y=0, .w=160, .h=144};
            SDL_SetRenderDrawColor(this->renderer, 64, 0, 0, 0xFF);
            SDL_RenderDrawRect(this->renderer, &rect);
            SDL_RenderDrawLine(this->renderer, 256-SCROLL_X, 0, 256-SCROLL_X, 256);
            SDL_RenderDrawLine(this->renderer, 0, 256-SCROLL_Y, 256, 256-SCROLL_Y);
        }
    }

    // Window tiles
    if (LCDC & LCDC_WINDOW_ENABLED) {
        u8 WND_Y = this->cpu->ram->get(IO_WY);
        u8 WND_X = this->cpu->ram->get(IO_WX);
        bool tile_offset = !(LCDC & LCDC_DATA_SRC);
        u16 window_map = (LCDC & LCDC_WINDOW_MAP) ? WINDOW_MAP_1 : WINDOW_MAP_0;

        // blank out the background
        SDL_Rect rect = {.x=WND_X - 7, .y=WND_Y, .w=160, .h=144};
        SDL_FillRect(this->buffer, &rect, bgp[0]);

        for (int tile_y = 0; tile_y < 18; tile_y++) {
            for (int tile_x = 0; tile_x < 20; tile_x++) {
                u16 tile_id = this->cpu->ram->get(window_map + tile_y * 32 + tile_x);
                if (tile_offset && tile_id < 0x80) tile_id += 0x100;
                SDL_Point xy = {
                    .x = tile_x * 8 + WND_X - 7,
                    .y = tile_y * 8 + WND_Y,
                };
                this->paint_tile(this->buffer, tile_id, &xy, bgp, false, false);
            }
        }

        if(debug) {
            SDL_SetRenderDrawColor(this->renderer, 0, 64, 0, 0xFF);
            SDL_RenderDrawRect(this->renderer, &rect);
        }
    }

    // Sprites
    if (LCDC & LCDC_OBJ_ENABLED) {
        bool dbl = (bool)(LCDC & LCDC_OBJ_SIZE);

        // TODO: sorted by x
        Sprite sprites[40];
        memcpy(sprites, &this->cpu->ram->data[OAM_BASE], 40 * sizeof(Sprite));
        for(auto sprite: sprites) {
            if(sprite.is_live()) {
                u32 *palette = sprite.palette ? obp1 : obp0;
                //printf("Drawing sprite %d (from %04X) at %d,%d\n", tile_id, OAM_BASE + (sprite_id * 4) + 0, x, y);
                SDL_Point xy = {
                    .x = sprite.x - 8,
                    .y = sprite.y - 16,
                };
                this->paint_tile(this->buffer, sprite.tile_id, &xy, palette, sprite.x_flip, sprite.y_flip);

                if(dbl) {
                    xy.y = sprite.y - 8;
                    this->paint_tile(this->buffer, sprite.tile_id+1, &xy, palette, sprite.x_flip, sprite.y_flip);
                }
            }
        }
        // lines go over the top of sprites, so can't put them into the same loop
        if(debug) {
            for(auto sprite: sprites) {
                if(sprite.is_live()) {
                    int x1 = sprite.x - 8;
                    int y1 = sprite.y - 16;
                    int x2 = 256 + (sprite.tile_id % 32) * 8;
                    int y2 = (sprite.tile_id / 32) * 8;
                    SDL_SetRenderDrawColor(this->renderer, 0, 0, 64, 0xFF);
                    SDL_RenderDrawLine(renderer, x1 + 4, y1 + 4, x2 + 4, y2 + 4);
                }
            }
        }
    }

    if(this->window) {
        SDL_Surface *window_surface = SDL_GetWindowSurface(window);
        SDL_BlitScaled(this->buffer, nullptr, window_surface, nullptr);
        SDL_UpdateWindowSurface(window);
    }
    return true;
}

void GPU::paint_tile(SDL_Surface *surf, i16 tile_id, SDL_Point *offset, u32 *palette, bool flip_x, bool flip_y) {
    //SDL_FillRect(surf, nullptr, SDL_MapRGBA(this->buffer->format, 0, 0, 0, 0));
    for (int y=0; y<8; y++) {
        u8 low_byte = this->cpu->ram->get(TILE_DATA + tile_id * 16 + y * 2);
        u8 high_byte = this->cpu->ram->get(TILE_DATA + tile_id * 16 + (y * 2) + 1);
        for (int x = 0; x < 8; x++) {
            u8 low_bit = (low_byte >> (7 - x)) & (u8)0x1;
            u8 high_bit = (high_byte >> (7 - x)) & (u8)0x1;
            u8 px = (high_bit << 1) | low_bit;
            // pallette #0 = transparent, so don't draw anything
            if(px) {
                SDL_Rect rect = {
                    .x=offset->x + (flip_x ? 7-x : x),
                    .y=offset->y + (flip_y ? 7-y : y),
                    .w=1, .h=1
                };
                SDL_FillRect(surf, &rect, palette[px]);
            }
        }
    }
}

bool Sprite::is_live() {
    return x > 0 && x < 168 && y > 0 && y < 160;
}