#include <SDL2/SDL.h>

#include "consts.h"
#include "cpu.h"
#include "gpu.h"
#include "ram.h"

struct Sprite {
    u8 y;
    u8 x;
    u8 tile_id;
    union {
        u8 flags;
        struct {
            unsigned char _empty : 4;
            unsigned char palette : 1;
            unsigned char x_flip : 1;
            unsigned char y_flip : 1;
            unsigned char behind : 1;
        };
    };
};

static const u8 LCDC_ENABLED = 1 << 7;
static const u8 LCDC_WINDOW_MAP = 1 << 6;
static const u8 LCDC_WINDOW_ENABLED = 1 << 5;
static const u8 LCDC_DATA_SRC = 1 << 4;
static const u8 LCDC_BG_MAP = 1 << 3;
static const u8 LCDC_OBJ_SIZE = 1 << 2;
static const u8 LCDC_OBJ_ENABLED = 1 << 1;
static const u8 LCDC_BG_WIN_ENABLED = 1 << 0;

static const u8 STAT_LYC_INTERRUPT = 1 << 6;
static const u8 STAT_OAM_INTERRUPT = 1 << 5;
static const u8 STAT_VBLANK_INTERRUPT = 1 << 4;
static const u8 STAT_HBLANK_INTERRUPT = 1 << 3;
static const u8 STAT_LYC_EQUAL = 1 << 2;
static const u8 STAT_MODE_BITS = 1 << 1 | 1 << 0;

static const u8 STAT_HBLANK = 0x00;
static const u8 STAT_VBLANK = 0x01;
static const u8 STAT_OAM = 0x02;
static const u8 STAT_DRAWING = 0x03;

static const u16 SCALE = 2;

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

static inline SDL_Color gen_hue(u8 n) {
    u8 region = n / 43;
    u8 remainder = (n - (region * 43)) * 6;

    u8 q = 255 - remainder;
    u8 t = remainder;
    SDL_Color rv;

    switch (region) {
        case 0:
            rv.r = 255, rv.g = t, rv.b = 0, rv.a = 0xFF;
            break;
        case 1:
            rv.r = q, rv.g = 255, rv.b = 0, rv.a = 0xFF;
            break;
        case 2:
            rv.r = 0, rv.g = 255, rv.b = t, rv.a = 0xFF;
            break;
        case 3:
            rv.r = 0, rv.g = q, rv.b = 255, rv.a = 0xFF;
            break;
        case 4:
            rv.r = t, rv.g = 0, rv.b = 255, rv.a = 0xFF;
            break;
        default:
            rv.r = 255, rv.g = 0, rv.b = q, rv.a = 0xFF;
            break;
    }

    return rv;
}

static inline bool sprite_is_live(struct Sprite *self) {
    return self->x > 0 && self->x < 168 && self->y > 0 && self->y < 160;
}

static inline void gpu_paint_tile_line(
    struct GPU *self, i16 tile_id, SDL_Point *offset, SDL_Color *palette, bool flip_x, bool flip_y, i32 y
) {
    u16 addr = (MEM_TILE_DATA + tile_id * 16 + y * 2);
    u8 low_byte = ram_get(self->ram, addr);
    u8 high_byte = ram_get(self->ram, addr + 1);
    for (int x = 0; x < 8; x++) {
        u8 low_bit = (low_byte >> (7 - x)) & 0x01;
        u8 high_bit = (high_byte >> (7 - x)) & 0x01;
        u8 px = (high_bit << 1) | low_bit;
        // pallette #0 = transparent, so don't draw anything
        if (px > 0) {
            SDL_Point xy = {
                .x = offset->x + (flip_x ? 7 - x : x),
                .y = offset->y + (flip_y ? 7 - y : y),
            };
            SDL_Color c = palette[px];
            SDL_SetRenderDrawColor(self->renderer, c.r, c.g, c.b, c.a);
            SDL_RenderDrawPoint(self->renderer, xy.x, xy.y);
        }
    }
}

static inline void
gpu_paint_tile(struct GPU *self, i16 tile_id, SDL_Point *offset, SDL_Color *palette, bool flip_x, bool flip_y) {
    for (int y = 0; y < 8; y++) {
        gpu_paint_tile_line(self, tile_id, offset, palette, flip_x, flip_y, y);
    }

    if (self->debug) {
        SDL_Rect rect = {
            .x = offset->x,
            .y = offset->y,
            .w = 8,
            .h = 8,
        };
        SDL_Color c = gen_hue(tile_id);
        SDL_SetRenderDrawColor(self->renderer, c.r, c.g, c.b, c.a);
        SDL_RenderDrawRect(self->renderer, &rect);
    }
}

static inline void gpu_draw_line(struct GPU *self, i32 ly) {
    u8 lcdc = ram_get(self->ram, MEM_LCDC);

    // Background tiles
    if (lcdc & LCDC_BG_WIN_ENABLED) {
        u8 scroll_y = ram_get(self->ram, MEM_SCY);
        u8 scroll_x = ram_get(self->ram, MEM_SCX);
        bool tile_offset = !(lcdc & LCDC_DATA_SRC); // @TODO correct?
        u16 tile_map = (lcdc & LCDC_BG_MAP) ? MEM_MAP_1 : MEM_MAP_0;

        if (self->debug) {
            SDL_Point xy = {.x = 256 - scroll_x, .y = ly};
            SDL_SetRenderDrawColor(self->renderer, 255, 0, 0, 0xFF);
            SDL_RenderDrawPoint(self->renderer, xy.x, xy.y);
        }

        u8 y_in_bgmap = (ly + scroll_y) % 256;
        u8 tile_y = y_in_bgmap / 8;
        u8 tile_sub_y = y_in_bgmap % 8;

        for (int lx = 0; lx <= 160; lx += 8) {
            u8 x_in_bgmap = (lx + scroll_x) % 256;
            u8 tile_x = x_in_bgmap / 8;
            u8 tile_sub_x = x_in_bgmap % 8;

            i16 tile_id = ram_get(self->ram, tile_map + tile_y * 32 + tile_x);
            if (tile_offset && tile_id < 0x80) {
                tile_id += 0x100;
            }
            SDL_Point xy = {
                .x = lx - tile_sub_x,
                .y = ly - tile_sub_y,
            };
            gpu_paint_tile_line(self, tile_id, &xy, self->bgp, false, false, tile_sub_y);
        }
    }

    // Window tiles
    if (lcdc & LCDC_WINDOW_ENABLED) {
        u8 wnd_y = ram_get(self->ram, MEM_WY);
        u8 wnd_x = ram_get(self->ram, MEM_WX);
        bool tile_offset = !(lcdc & LCDC_DATA_SRC); // @todo check
        u16 tile_map = (lcdc & LCDC_WINDOW_MAP) ? MEM_MAP_1 : MEM_MAP_0;

        // blank out the background
        SDL_Rect rect = {
            .x = wnd_x - 7,
            .y = wnd_y,
            .w = 160,
            .h = 144,
        };
        SDL_Color c = self->bgp[0];
        SDL_SetRenderDrawColor(self->renderer, c.r, c.g, c.b, c.a);
        SDL_RenderFillRect(self->renderer, &rect);

        u8 y_in_bgmap = ly - wnd_y;
        u8 tile_y = y_in_bgmap / 8;
        u8 tile_sub_y = y_in_bgmap % 8;

        for (int tile_x = 0; tile_x < 20; tile_x++) {
            u8 tile_id = ram_get(self->ram, tile_map + tile_y * 32 + tile_x);
            if (tile_offset && tile_id < 0x80) {
                tile_id += 0x100;
            }
            SDL_Point xy = {
                .x = tile_x * 8 + wnd_x - 7,
                .y = tile_y * 8 + wnd_y,
            };
            gpu_paint_tile_line(self, tile_id, &xy, self->bgp, false, false, tile_sub_y);
        }
    }

    // Sprites
    if (lcdc & LCDC_OBJ_ENABLED) {
        u8 dbl = lcdc & LCDC_OBJ_SIZE;

        // TODO: sorted by x
        // auto sprites: [Sprite; 40] = [];
        // memcpy(sprites, &ram.data[OAM_BASE], 40 * sizeof(Sprite));
        // for sprite in sprites.iter() {
        for (int n = 0; n < 40; n++) {
            struct Sprite sprite = {
                .y = ram_get(self->ram, MEM_OAM_BASE + 4 * n + 0),
                .x = ram_get(self->ram, MEM_OAM_BASE + 4 * n + 1),
                .tile_id = ram_get(self->ram, MEM_OAM_BASE + 4 * n + 2),
                .flags = ram_get(self->ram, MEM_OAM_BASE + 4 * n + 3)};

            if (sprite_is_live(&sprite)) {
                SDL_Color *palette = sprite.palette ? self->obp1 : self->obp0;
                // printf("Drawing sprite %d (from %04X) at %d,%d\n", tile_id, OAM_BASE + (sprite_id * 4) + 0, x, y);
                SDL_Point xy = {
                    .x = sprite.x - 8,
                    .y = sprite.y - 16,
                };
                gpu_paint_tile(self, sprite.tile_id, &xy, palette, sprite.x_flip, sprite.y_flip);

                if (dbl) {
                    xy.y = sprite.y - 8;
                    gpu_paint_tile(self, sprite.tile_id + 1, &xy, palette, sprite.x_flip, sprite.y_flip);
                }
            }
        }
    }
}

static inline void gpu_draw_debug(struct GPU *self) {
    u8 lcdc = ram_get(self->ram, MEM_LCDC);

    // Tile data
    u8 tile_display_width = 32;
    for (int tile_id = 0; tile_id < 384; tile_id++) {
        SDL_Point xy = {
            .x = 160 + (tile_id % tile_display_width) * 8,
            .y = (tile_id / tile_display_width) * 8,
        };
        gpu_paint_tile(self, tile_id, &xy, self->bgp, false, false);
    }

    // Background scroll border
    if (lcdc & LCDC_BG_WIN_ENABLED) {
        SDL_Rect rect = {.x = 0, .y = 0, .w = 160, .h = 144};
        SDL_SetRenderDrawColor(self->renderer, 255, 0, 0, 0xFF);
        SDL_RenderDrawRect(self->renderer, &rect);
    }

    // Window tiles
    if (lcdc & LCDC_WINDOW_ENABLED) {
        u8 wnd_y = ram_get(self->ram, MEM_WY);
        u8 wnd_x = ram_get(self->ram, MEM_WX);
        SDL_Rect rect = {.x = wnd_x - 7, .y = wnd_y, .w = 160, .h = 144};
        SDL_SetRenderDrawColor(self->renderer, 0, 0, 255, 0xFF);
        SDL_RenderDrawRect(self->renderer, &rect);
    }
}

static inline void gpu_update_palettes(struct GPU *self) {
    u8 raw_bgp = ram_get(self->ram, MEM_BGP);
    self->bgp[0] = self->colors[(raw_bgp >> 0) & 0x3];
    self->bgp[1] = self->colors[(raw_bgp >> 2) & 0x3];
    self->bgp[2] = self->colors[(raw_bgp >> 4) & 0x3];
    self->bgp[3] = self->colors[(raw_bgp >> 6) & 0x3];

    u8 raw_obp0 = ram_get(self->ram, MEM_OBP0);
    self->obp0[0] = self->colors[(raw_obp0 >> 0) & 0x3];
    self->obp0[1] = self->colors[(raw_obp0 >> 2) & 0x3];
    self->obp0[2] = self->colors[(raw_obp0 >> 4) & 0x3];
    self->obp0[3] = self->colors[(raw_obp0 >> 6) & 0x3];

    u8 raw_obp1 = ram_get(self->ram, MEM_OBP1);
    self->obp1[0] = self->colors[(raw_obp1 >> 0) & 0x3];
    self->obp1[1] = self->colors[(raw_obp1 >> 2) & 0x3];
    self->obp1[2] = self->colors[(raw_obp1 >> 4) & 0x3];
    self->obp1[3] = self->colors[(raw_obp1 >> 6) & 0x3];
}

void gpu_ctor(struct GPU *self, struct CPU *cpu, struct RAM *ram, char *title, bool headless, bool debug) {
    *self = (struct GPU){
        .cpu = cpu,
        .ram = ram,
        .debug = debug,
        .colors = {
                   {.r = 0x9B, .g = 0xBC, .b = 0x0F, .a = 0xFF},
                   {.r = 0x8B, .g = 0xAC, .b = 0x0F, .a = 0xFF},
                   {.r = 0x30, .g = 0x62, .b = 0x30, .a = 0xFF},
                   {.r = 0x0F, .g = 0x38, .b = 0x0F, .a = 0xFF},
                   }
    };

    // Window
    int w = 160, h = 144;
    if (debug) {
        w = 160 + 256;
        h = 144;
    }
    if (!headless) {
        SDL_InitSubSystem(SDL_INIT_VIDEO);
        char title_buf[64];
        snprintf(title_buf, 64, "RosettaBoy - %s", title);
        self->hw_window = SDL_CreateWindow(
            title_buf,                                      // window title
            SDL_WINDOWPOS_UNDEFINED,                        // initial x position
            SDL_WINDOWPOS_UNDEFINED,                        // initial y position
            w * SCALE,                                      // width, in pixels
            h * SCALE,                                      // height, in pixels
            SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE // flags - see below
        );
        self->hw_renderer = SDL_CreateRenderer(self->hw_window, -1, 0);
        SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "nearest"); // vs "linear"
        SDL_RenderSetLogicalSize(self->hw_renderer, w, h);
        self->hw_buffer =
            SDL_CreateTexture(self->hw_renderer, SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STREAMING, w, h);
    } else {
        self->hw_window = NULL;
        self->hw_renderer = NULL;
        self->hw_buffer = NULL;
    }
    self->buffer = SDL_CreateRGBSurface(0, w, h, 32, rmask, gmask, bmask, amask);
    self->renderer = SDL_CreateSoftwareRenderer(self->buffer);

    // printf("SDL_Init failed: %s\n", SDL_GetError());
};

void gpu_dtor(struct GPU *self) {
    SDL_FreeSurface(self->buffer);
    if (self->hw_window) {
        SDL_DestroyWindow(self->hw_window);
    }
    SDL_Quit();
}

void gpu_tick(struct GPU *self) {
    self->cycle++;

    // CPU STOP stops all LCD activity until a button is pressed
    if (cpu_is_stopped(self->cpu)) {
        return;
    }

    // Check if LCD enabled at all
    u8 lcdc = ram_get(self->ram, MEM_LCDC);
    if (!(lcdc & LCDC_ENABLED)) {
        // When LCD is re-enabled, LY is 0
        // Does it become 0 as soon as disabled??
        ram_set(self->ram, MEM_LY, 0);
        if (!self->debug) {
            return;
        }
    }

    u8 lx = self->cycle % 114;
    u8 ly = (self->cycle / 114) % 154;
    ram_set(self->ram, MEM_LY, ly);

    u8 stat = ram_get(self->ram, MEM_STAT);
    stat &= ~STAT_MODE_BITS;
    stat &= ~STAT_LYC_EQUAL;

    // LYC compare & interrupt
    if (ly == ram_get(self->ram, MEM_LYC)) {
        stat |= STAT_LYC_EQUAL;
        if (stat & STAT_LYC_INTERRUPT) {
            cpu_interrupt(self->cpu, INTERRUPT_STAT);
        }
    }

    // Set mode
    if (lx == 0 && ly < 144) {
        stat |= STAT_OAM;
        if (stat & STAT_OAM_INTERRUPT) {
            cpu_interrupt(self->cpu, INTERRUPT_STAT);
        }
    } else if (lx == 20 && ly < 144) {
        stat |= STAT_DRAWING;
        if (ly == 0) {
            // TODO: how often should we update palettes?
            // Should every pixel reference them directly?
            gpu_update_palettes(self);
            SDL_Color c = self->bgp[0];
            SDL_SetRenderDrawColor(self->renderer, c.r, c.g, c.b, c.a);
            SDL_RenderClear(self->renderer);
        }
        gpu_draw_line(self, ly);
        if (ly == 143) {
            if (self->debug) {
                gpu_draw_debug(self);
            }
            if (self->hw_renderer) {
                SDL_UpdateTexture(self->hw_buffer, NULL, self->buffer->pixels, self->buffer->pitch);
                SDL_RenderCopy(self->hw_renderer, self->hw_buffer, NULL, NULL);
                SDL_RenderPresent(self->hw_renderer);
            }
        }
    } else if (lx == 63 && ly < 144) {
        stat |= STAT_HBLANK;
        if (stat & STAT_HBLANK_INTERRUPT) {
            cpu_interrupt(self->cpu, INTERRUPT_STAT);
        }
    } else if (lx == 0 && ly == 144) {
        stat |= STAT_VBLANK;
        if (stat & STAT_VBLANK_INTERRUPT) {
            cpu_interrupt(self->cpu, INTERRUPT_STAT);
        }
        cpu_interrupt(self->cpu, INTERRUPT_VBLANK);
    }
    ram_set(self->ram, MEM_STAT, stat);
}
