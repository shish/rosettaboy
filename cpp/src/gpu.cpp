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

GPU::GPU(CPU *cpu, char *title, bool headless, bool debug) {
    this->cpu = cpu;
    this->debug = debug;

    // Window
    int w = 160, h = 144;
    if(this->debug) {
        w = 160 + 256;
        h = 144;
    }
    if(!headless) {
        SDL_InitSubSystem(SDL_INIT_VIDEO);
        char title_buf[64];
        snprintf(title_buf, 64, "RosettaBoy - %s", title);
        this->hw_window = SDL_CreateWindow(
            title_buf,                                      // window title
            SDL_WINDOWPOS_UNDEFINED,                        // initial x position
            SDL_WINDOWPOS_UNDEFINED,                        // initial y position
            w * SCALE,                                      // width, in pixels
            h * SCALE,                                      // height, in pixels
            SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE // flags - see below
        );
        this->hw_renderer = SDL_CreateRenderer(this->hw_window, -1, 0);
        SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "nearest"); // vs "linear"
        SDL_RenderSetLogicalSize(this->hw_renderer, w, h);
        this->hw_buffer =
            SDL_CreateTexture(this->hw_renderer, SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STREAMING, w, h);
    } else {
        this->hw_window = nullptr;
        this->hw_renderer = nullptr;
        this->hw_buffer = nullptr;
    }
    this->buffer = SDL_CreateRGBSurface(0, w, h, 32, rmask, gmask, bmask, amask);
    this->renderer = SDL_CreateSoftwareRenderer(this->buffer);

    // Colors
    this->colors[0] = {.r = 0x9B, .g = 0xBC, .b = 0x0F, .a = 0xFF};
    this->colors[1] = {.r = 0x8B, .g = 0xAC, .b = 0x0F, .a = 0xFF};
    this->colors[2] = {.r = 0x30, .g = 0x62, .b = 0x30, .a = 0xFF};
    this->colors[3] = {.r = 0x0F, .g = 0x38, .b = 0x0F, .a = 0xFF};
    // printf("SDL_Init failed: %s\n", SDL_GetError());
};

GPU::~GPU() {
    SDL_FreeSurface(this->buffer);
    if(this->hw_window) SDL_DestroyWindow(this->hw_window);
    SDL_Quit();
}

void GPU::tick() {
    this->cycle++;

    // CPU STOP stops all LCD activity until a button is pressed
    if(this->cpu->stop) {
        return;
    }

    // Check if LCD enabled at all
    u8 lcdc = this->cpu->ram->get(Mem::LCDC);
    if(!(lcdc & LCDC::ENABLED)) {
        // When LCD is re-enabled, LY is 0
        // Does it become 0 as soon as disabled??
        this->cpu->ram->set(Mem::LY, 0);
        if(!this->debug) {
            return;
        }
    }

    u8 lx = this->cycle % 114;
    u8 ly = (this->cycle / 114) % 154;
    this->cpu->ram->set(Mem::LY, ly);

    u8 stat = this->cpu->ram->get(Mem::STAT);
    stat &= ~Stat::MODE_BITS;
    stat &= ~Stat::LYC_EQUAL;

    // LYC compare & interrupt
    if(ly == this->cpu->ram->get(Mem::LYC)) {
        stat |= Stat::LYC_EQUAL;
        if(stat & Stat::LYC_INTERRUPT) {
            this->cpu->interrupt(Interrupt::STAT);
        }
    }

    // Set mode
    if(lx == 0 && ly < 144) {
        stat |= Stat::OAM;
        if(stat & Stat::OAM_INTERRUPT) {
            this->cpu->interrupt(Interrupt::STAT);
        }
    } else if(lx == 20 && ly < 144) {
        stat |= Stat::DRAWING;
        if(ly == 0) {
            // TODO: how often should we update palettes?
            // Should every pixel reference them directly?
            this->update_palettes();
            auto c = this->bgp[0];
            SDL_SetRenderDrawColor(this->renderer, c.r, c.g, c.b, c.a);
            SDL_RenderClear(this->renderer);
        }
        this->draw_line(ly);
        if(ly == 143) {
            if(this->debug) {
                this->draw_debug();
            }
            if(this->hw_renderer) {
                SDL_UpdateTexture(this->hw_buffer, NULL, this->buffer->pixels, this->buffer->pitch);
                SDL_RenderCopy(this->hw_renderer, this->hw_buffer, NULL, NULL);
                SDL_RenderPresent(this->hw_renderer);
            }
        }
    } else if(lx == 63 && ly < 144) {
        stat |= Stat::HBLANK;
        if(stat & Stat::HBLANK_INTERRUPT) {
            this->cpu->interrupt(Interrupt::STAT);
        }
    } else if(lx == 0 && ly == 144) {
        stat |= Stat::VBLANK;
        if(stat & Stat::VBLANK_INTERRUPT) {
            this->cpu->interrupt(Interrupt::STAT);
        }
        this->cpu->interrupt(Interrupt::VBLANK);
    }
    this->cpu->ram->set(Mem::STAT, stat);
}

void GPU::update_palettes() {
    u8 raw_bgp = this->cpu->ram->get(Mem::BGP);
    this->bgp[0] = this->colors[(raw_bgp >> 0) & 0x3];
    this->bgp[1] = this->colors[(raw_bgp >> 2) & 0x3];
    this->bgp[2] = this->colors[(raw_bgp >> 4) & 0x3];
    this->bgp[3] = this->colors[(raw_bgp >> 6) & 0x3];

    u8 raw_obp0 = this->cpu->ram->get(Mem::OBP0);
    this->obp0[0] = this->colors[(raw_obp0 >> 0) & 0x3];
    this->obp0[1] = this->colors[(raw_obp0 >> 2) & 0x3];
    this->obp0[2] = this->colors[(raw_obp0 >> 4) & 0x3];
    this->obp0[3] = this->colors[(raw_obp0 >> 6) & 0x3];

    u8 raw_obp1 = this->cpu->ram->get(Mem::OBP1);
    this->obp1[0] = this->colors[(raw_obp1 >> 0) & 0x3];
    this->obp1[1] = this->colors[(raw_obp1 >> 2) & 0x3];
    this->obp1[2] = this->colors[(raw_obp1 >> 4) & 0x3];
    this->obp1[3] = this->colors[(raw_obp1 >> 6) & 0x3];
}

void GPU::draw_debug() {
    u8 lcdc = this->cpu->ram->get(Mem::LCDC);

    // Tile data
    u8 tile_display_width = 32;
    for(int tile_id = 0; tile_id < 384; tile_id++) {
        SDL_Point xy = {
            .x = 160 + (tile_id % tile_display_width) * 8,
            .y = (tile_id / tile_display_width) * 8,
        };
        this->paint_tile(tile_id, &xy, this->bgp, false, false);
    }

    // Background scroll border
    if(lcdc & LCDC::BG_WIN_ENABLED) {
        SDL_Rect rect = {.x = 0, .y = 0, .w = 160, .h = 144};
        SDL_SetRenderDrawColor(this->renderer, 255, 0, 0, 0xFF);
        SDL_RenderDrawRect(this->renderer, &rect);
    }

    // Window tiles
    if(lcdc & LCDC::WINDOW_ENABLED) {
        u8 wnd_y = this->cpu->ram->get(Mem::WY);
        u8 wnd_x = this->cpu->ram->get(Mem::WX);
        SDL_Rect rect = {.x = wnd_x - 7, .y = wnd_y, .w = 160, .h = 144};
        SDL_SetRenderDrawColor(this->renderer, 0, 0, 255, 0xFF);
        SDL_RenderDrawRect(this->renderer, &rect);
    }
}

void GPU::draw_line(i32 ly) {
    auto lcdc = this->cpu->ram->get(Mem::LCDC);

    // Background tiles
    if(lcdc & LCDC::BG_WIN_ENABLED) {
        auto scroll_y = this->cpu->ram->get(Mem::SCY);
        auto scroll_x = this->cpu->ram->get(Mem::SCX);
        auto tile_offset = !(lcdc & LCDC::DATA_SRC);
        auto tile_map = (lcdc & LCDC::BG_MAP) ? Mem::MAP_1 : Mem::MAP_0;

        if(this->debug) {
            SDL_Point xy = {.x = 256 - scroll_x, .y = ly};
            SDL_SetRenderDrawColor(this->renderer, 255, 0, 0, 0xFF);
            SDL_RenderDrawPoint(this->renderer, xy.x, xy.y);
        }

        auto y_in_bgmap = (ly + scroll_y) % 256;
        auto tile_y = y_in_bgmap / 8;
        auto tile_sub_y = y_in_bgmap % 8;

        for(int lx = 0; lx <= 160; lx += 8) {
            auto x_in_bgmap = (lx + scroll_x) % 256;
            auto tile_x = x_in_bgmap / 8;
            auto tile_sub_x = x_in_bgmap % 8;

            i16 tile_id = this->cpu->ram->get(tile_map + tile_y * 32 + tile_x);
            if(tile_offset && tile_id < 0x80) {
                tile_id += 0x100;
            }
            SDL_Point xy = {
                .x = lx - tile_sub_x,
                .y = ly - tile_sub_y,
            };
            this->paint_tile_line(tile_id, &xy, this->bgp, false, false, tile_sub_y);
        }
    }

    // Window tiles
    if(lcdc & LCDC::WINDOW_ENABLED) {
        auto wnd_y = this->cpu->ram->get(Mem::WY);
        auto wnd_x = this->cpu->ram->get(Mem::WX);
        auto tile_offset = !(lcdc & LCDC::DATA_SRC);
        auto tile_map = (lcdc & LCDC::WINDOW_MAP) ? Mem::MAP_1 : Mem::MAP_0;

        // blank out the background
        SDL_Rect rect = {
            .x = wnd_x - 7,
            .y = wnd_y,
            .w = 160,
            .h = 144,
        };
        auto c = this->bgp[0];
        SDL_SetRenderDrawColor(this->renderer, c.r, c.g, c.b, c.a);
        SDL_RenderFillRect(this->renderer, &rect);

        auto y_in_bgmap = ly - wnd_y;
        auto tile_y = y_in_bgmap / 8;
        auto tile_sub_y = y_in_bgmap % 8;

        for(int tile_x = 0; tile_x < 20; tile_x++) {
            auto tile_id = this->cpu->ram->get(tile_map + tile_y * 32 + tile_x);
            if(tile_offset && tile_id < 0x80) {
                tile_id += 0x100;
            }
            SDL_Point xy = {
                .x = tile_x * 8 + wnd_x - 7,
                .y = tile_y * 8 + wnd_y,
            };
            this->paint_tile_line(tile_id, &xy, this->bgp, false, false, tile_sub_y);
        }
    }

    // Sprites
    if(lcdc & LCDC::OBJ_ENABLED) {
        auto dbl = lcdc & LCDC::OBJ_SIZE;

        // TODO: sorted by x
        // auto sprites: [Sprite; 40] = [];
        // memcpy(sprites, &ram.data[OAM_BASE], 40 * sizeof(Sprite));
        // for sprite in sprites.iter() {
        for(int n = 0; n < 40; n++) {
            Sprite sprite;
            sprite.y = this->cpu->ram->get(Mem::OAM_BASE + 4 * n + 0);
            sprite.x = this->cpu->ram->get(Mem::OAM_BASE + 4 * n + 1);
            sprite.tile_id = this->cpu->ram->get(Mem::OAM_BASE + 4 * n + 2);
            sprite.flags = this->cpu->ram->get(Mem::OAM_BASE + 4 * n + 3);

            if(sprite.is_live()) {
                auto palette = sprite.palette ? this->obp1 : this->obp0;
                // printf("Drawing sprite %d (from %04X) at %d,%d\n", tile_id, OAM_BASE + (sprite_id * 4) + 0, x, y);
                SDL_Point xy = {
                    .x = sprite.x - 8,
                    .y = sprite.y - 16,
                };
                this->paint_tile(sprite.tile_id, &xy, palette, sprite.x_flip, sprite.y_flip);

                if(dbl) {
                    xy.y = sprite.y - 8;
                    this->paint_tile(sprite.tile_id + 1, &xy, palette, sprite.x_flip, sprite.y_flip);
                }
            }
        }
    }
}

void GPU::paint_tile(i16 tile_id, SDL_Point *offset, SDL_Color *palette, bool flip_x, bool flip_y) {
    for(int y = 0; y < 8; y++) {
        this->paint_tile_line(tile_id, offset, palette, flip_x, flip_y, y);
    }

    if(this->debug) {
        SDL_Rect rect = {
            .x = offset->x,
            .y = offset->y,
            .w = 8,
            .h = 8,
        };
        auto c = gen_hue(tile_id);
        SDL_SetRenderDrawColor(this->renderer, c.r, c.g, c.b, c.a);
        SDL_RenderDrawRect(this->renderer, &rect);
    }
}

void GPU::paint_tile_line(i16 tile_id, SDL_Point *offset, SDL_Color *palette, bool flip_x, bool flip_y, i32 y) {
    u16 addr = (Mem::TILE_DATA + tile_id * 16 + y * 2);
    u8 low_byte = this->cpu->ram->get(addr);
    u8 high_byte = this->cpu->ram->get(addr + 1);
    for(int x = 0; x < 8; x++) {
        u8 low_bit = (low_byte >> (7 - x)) & 0x01;
        u8 high_bit = (high_byte >> (7 - x)) & 0x01;
        u8 px = (high_bit << 1) | low_bit;
        // pallette #0 = transparent, so don't draw anything
        if(px > 0) {
            SDL_Point xy = {
                .x = offset->x + (flip_x ? 7 - x : x),
                .y = offset->y + (flip_y ? 7 - y : y),
            };
            auto c = palette[px];
            SDL_SetRenderDrawColor(this->renderer, c.r, c.g, c.b, c.a);
            SDL_RenderDrawPoint(this->renderer, xy.x, xy.y);
        }
    }
}

SDL_Color gen_hue(u8 n) {
    u8 region = n / 43;
    u8 remainder = (n - (region * 43)) * 6;

    u8 q = 255 - remainder;
    u8 t = remainder;

    switch(region) {
        case 0: return {.r = 255, .g = t, .b = 0, .a = 0xFF};
        case 1: return {.r = q, .g = 255, .b = 0, .a = 0xFF};
        case 2: return {.r = 0, .g = 255, .b = t, .a = 0xFF};
        case 3: return {.r = 0, .g = q, .b = 255, .a = 0xFF};
        case 4: return {.r = t, .g = 0, .b = 255, .a = 0xFF};
        default: return {.r = 255, .g = 0, .b = q, .a = 0xFF};
    }
}

bool Sprite::is_live() { return x > 0 && x < 168 && y > 0 && y < 160; }