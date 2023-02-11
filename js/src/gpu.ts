import sdl from "@kmamal/sdl";
import { Mem, Interrupt } from "./consts";
import { CPU } from "./cpu";

const SCALE = 2;

const rmask = 0x000000ff;
const gmask = 0x0000ff00;
const bmask = 0x00ff0000;
const amask = 0xff000000;

enum LCDC {
    ENABLED = 1 << 7,
    WINDOW_MAP = 1 << 6,
    WINDOW_ENABLED = 1 << 5,
    DATA_SRC = 1 << 4,
    BG_MAP = 1 << 3,
    OBJ_SIZE = 1 << 2,
    OBJ_ENABLED = 1 << 1,
    BG_WIN_ENABLED = 1 << 0,
}

enum Stat {
    LYC_INTERRUPT = 1 << 6,
    OAM_INTERRUPT = 1 << 5,
    VBLANK_INTERRUPT = 1 << 4,
    HBLANK_INTERRUPT = 1 << 3,
    LYC_EQUAL = 1 << 2,
    MODE_BITS = (1 << 1) | (1 << 0),

    HBLANK = 0x00,
    VBLANK = 0x01,
    OAM = 0x02,
    DRAWING = 0x03,
}

export class GPU {
    cpu: CPU;
    headless: boolean;
    debug: boolean;
    hw_window: sdl.Sdl.Video.Window | null;
    colors: Array<SDL_Color>;
    bgp: Array<SDL_Color>;
    obp0: Array<SDL_Color>;
    obp1: Array<SDL_Color>;
    cycle: number;

    constructor(cpu: CPU, title: string, headless: boolean, debug: boolean) {
        this.cpu = cpu;
        this.headless = headless;
        this.debug = debug;
        this.cycle = 0;

        // Window
        let w = 160,
            h = 144;
        if (this.debug) {
            w = 160 + 256;
            h = 144;
        }
        if (!headless) {
            this.hw_window = sdl.video.createWindow({
                title: `RosettaBoy - ${title}`,
                width: w * SCALE,
                height: h * SCALE,
                resizable: true,
                // SDL_WINDOW_ALLOW_HIGHDPI
            });
            // SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "nearest"); // vs "linear"
            // SDL_RenderSetLogicalSize(this.hw_renderer, w, h);
            // this.hw_buffer =
            //    SDL_CreateTexture(this.hw_renderer, SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STREAMING, w, h);
        } else {
            this.hw_window = null;
        }

        //this.buffer = SDL_CreateRGBSurface(0, w, h, 32, rmask, gmask, bmask, amask);
        //this.renderer = SDL_CreateSoftwareRenderer(this.buffer);

        // Colors
        this.colors = [
            { r: 0x9b, g: 0xbc, b: 0x0f, a: 0xff },
            { r: 0x8b, g: 0xac, b: 0x0f, a: 0xff },
            { r: 0x30, g: 0x62, b: 0x30, a: 0xff },
            { r: 0x0f, g: 0x38, b: 0x0f, a: 0xff },
        ];
        this.bgp = this.colors;
        this.obp0 = this.colors;
        this.obp1 = this.colors;
        // printf("SDL_Init failed: %s\n", SDL_GetError());
    }

    //    GPU::~GPU() {
    //        SDL_FreeSurface(this.buffer);
    //        if(this.hw_window) SDL_DestroyWindow(this.hw_window);
    //        SDL_Quit();
    //    }

    tick() {
        this.cycle++;

        // CPU STOP stops all LCD activity until a button is pressed
        if (this.cpu.stop) {
            return;
        }

        // Check if LCD enabled at all
        const lcdc: u8 = this.cpu.ram.get(Mem.LCDC);
        if (!(lcdc & LCDC.ENABLED)) {
            // When LCD is re-enabled, LY is 0
            // Does it become 0 as soon as disabled??
            this.cpu.ram.set(Mem.LY, 0);
            if (!this.debug) {
                return;
            }
        }

        const lx: u8 = this.cycle % 114;
        const ly: u8 = Math.floor(this.cycle / 114) % 154;
        this.cpu.ram.set(Mem.LY, ly);

        let stat: u8 = this.cpu.ram.get(Mem.STAT);
        stat &= ~Stat.MODE_BITS;
        stat &= ~Stat.LYC_EQUAL;

        // LYC compare & interrupt
        if (ly == this.cpu.ram.get(Mem.LYC)) {
            stat |= Stat.LYC_EQUAL;
            if (stat & Stat.LYC_INTERRUPT) {
                this.cpu.interrupt(Interrupt.STAT);
            }
        }

        // Set mode
        if (lx == 0 && ly < 144) {
            stat |= Stat.OAM;
            if (stat & Stat.OAM_INTERRUPT) {
                this.cpu.interrupt(Interrupt.STAT);
            }
        } else if (lx == 20 && ly < 144) {
            stat |= Stat.DRAWING;
            if (ly == 0) {
                // TODO: how often should we update palettes?
                // Should every pixel reference them directly?
                this.update_palettes();
                const c = this.bgp[0];
                //SDL_SetRenderDrawColor(this.renderer, c.r, c.g, c.b, c.a);
                //SDL_RenderClear(this.renderer);
            }
            this.draw_line(ly);
            if (ly == 143) {
                if (this.debug) {
                    this.draw_debug();
                }
                //if(this.hw_renderer) {
                //SDL_UpdateTexture(this.hw_buffer, NULL, this.buffer.pixels, this.buffer.pitch);
                //SDL_RenderCopy(this.hw_renderer, this.hw_buffer, NULL, NULL);
                //SDL_RenderPresent(this.hw_renderer);
                //}
            }
        } else if (lx == 63 && ly < 144) {
            stat |= Stat.HBLANK;
            if (stat & Stat.HBLANK_INTERRUPT) {
                this.cpu.interrupt(Interrupt.STAT);
            }
        } else if (lx == 0 && ly == 144) {
            stat |= Stat.VBLANK;
            if (stat & Stat.VBLANK_INTERRUPT) {
                this.cpu.interrupt(Interrupt.STAT);
            }
            this.cpu.interrupt(Interrupt.VBLANK);
        }
        this.cpu.ram.set(Mem.STAT, stat);
    }

    update_palettes() {
        const raw_bgp = this.cpu.ram.get(Mem.BGP);
        this.bgp[0] = this.colors[(raw_bgp >> 0) & 0x3];
        this.bgp[1] = this.colors[(raw_bgp >> 2) & 0x3];
        this.bgp[2] = this.colors[(raw_bgp >> 4) & 0x3];
        this.bgp[3] = this.colors[(raw_bgp >> 6) & 0x3];

        const raw_obp0 = this.cpu.ram.get(Mem.OBP0);
        this.obp0[0] = this.colors[(raw_obp0 >> 0) & 0x3];
        this.obp0[1] = this.colors[(raw_obp0 >> 2) & 0x3];
        this.obp0[2] = this.colors[(raw_obp0 >> 4) & 0x3];
        this.obp0[3] = this.colors[(raw_obp0 >> 6) & 0x3];

        const raw_obp1 = this.cpu.ram.get(Mem.OBP1);
        this.obp1[0] = this.colors[(raw_obp1 >> 0) & 0x3];
        this.obp1[1] = this.colors[(raw_obp1 >> 2) & 0x3];
        this.obp1[2] = this.colors[(raw_obp1 >> 4) & 0x3];
        this.obp1[3] = this.colors[(raw_obp1 >> 6) & 0x3];
    }

    draw_debug() {
        const lcdc: u8 = this.cpu.ram.get(Mem.LCDC);

        // Tile data
        const tile_display_width: u8 = 32;
        for (let tile_id = 0; tile_id < 384; tile_id++) {
            const xy: SDL_Point = {
                x: 160 + (tile_id % tile_display_width) * 8,
                y: Math.floor(tile_id / tile_display_width) * 8,
            };
            this.paint_tile(tile_id, xy, this.bgp, false, false);
        }

        // Background scroll border
        if (lcdc & LCDC.BG_WIN_ENABLED) {
            const rect: SDL_Rect = { x: 0, y: 0, w: 160, h: 144 };
            //SDL_SetRenderDrawColor(this.renderer, 255, 0, 0, 0xFF);
            //SDL_RenderDrawRect(this.renderer, &rect);
        }

        // Window tiles
        if (lcdc & LCDC.WINDOW_ENABLED) {
            const wnd_y: u8 = this.cpu.ram.get(Mem.WY);
            const wnd_x: u8 = this.cpu.ram.get(Mem.WX);
            const rect: SDL_Rect = { x: wnd_x - 7, y: wnd_y, w: 160, h: 144 };
            //SDL_SetRenderDrawColor(this.renderer, 0, 0, 255, 0xFF);
            //SDL_RenderDrawRect(this.renderer, &rect);
        }
    }

    draw_line(ly: number) {
        const lcdc: u8 = this.cpu.ram.get(Mem.LCDC);

        // Background tiles
        if (lcdc & LCDC.BG_WIN_ENABLED) {
            const scroll_y = this.cpu.ram.get(Mem.SCY);
            const scroll_x = this.cpu.ram.get(Mem.SCX);
            const tile_offset = !(lcdc & LCDC.DATA_SRC);
            const tile_map = lcdc & LCDC.BG_MAP ? Mem.Map1 : Mem.Map0;

            if (this.debug) {
                const xy: SDL_Point = { x: 256 - scroll_x, y: ly };
                //SDL_SetRenderDrawColor(this.renderer, 255, 0, 0, 0xFF);
                //SDL_RenderDrawPoint(this.renderer, xy.x, xy.y);
            }

            const y_in_bgmap = (ly + scroll_y) % 256;
            const tile_y = Math.floor(y_in_bgmap / 8);
            const tile_sub_y = y_in_bgmap % 8;

            for (let lx = 0; lx <= 160; lx += 8) {
                const x_in_bgmap = (lx + scroll_x) % 256;
                const tile_x = Math.floor(x_in_bgmap / 8);
                const tile_sub_x = x_in_bgmap % 8;

                let tile_id = this.cpu.ram.get(tile_map + tile_y * 32 + tile_x);
                if (tile_offset && tile_id < 0x80) {
                    tile_id += 0x100;
                }
                const xy: SDL_Point = {
                    x: lx - tile_sub_x,
                    y: ly - tile_sub_y,
                };
                this.paint_tile_line(
                    tile_id,
                    xy,
                    this.bgp,
                    false,
                    false,
                    tile_sub_y,
                );
            }
        }

        // Window tiles
        if (lcdc & LCDC.WINDOW_ENABLED) {
            const wnd_y = this.cpu.ram.get(Mem.WY);
            const wnd_x = this.cpu.ram.get(Mem.WX);
            const tile_offset = !(lcdc & LCDC.DATA_SRC);
            const tile_map = lcdc & LCDC.WINDOW_MAP ? Mem.Map1 : Mem.Map0;

            // blank out the background
            const rect: SDL_Rect = {
                x: wnd_x - 7,
                y: wnd_y,
                w: 160,
                h: 144,
            };
            const c = this.bgp[0];
            //SDL_SetRenderDrawColor(this.renderer, c.r, c.g, c.b, c.a);
            //SDL_RenderFillRect(this.renderer, &rect);

            const y_in_bgmap = ly - wnd_y;
            const tile_y = Math.floor(y_in_bgmap / 8);
            const tile_sub_y = y_in_bgmap % 8;

            for (let tile_x = 0; tile_x < 20; tile_x++) {
                let tile_id = this.cpu.ram.get(tile_map + tile_y * 32 + tile_x);
                if (tile_offset && tile_id < 0x80) {
                    tile_id += 0x100;
                }
                const xy: SDL_Point = {
                    x: tile_x * 8 + wnd_x - 7,
                    y: tile_y * 8 + wnd_y,
                };
                this.paint_tile_line(
                    tile_id,
                    xy,
                    this.bgp,
                    false,
                    false,
                    tile_sub_y,
                );
            }
        }

        // Sprites
        if (lcdc & LCDC.OBJ_ENABLED) {
            const dbl = lcdc & LCDC.OBJ_SIZE;

            // TODO: sorted by x
            // const sprites: [Sprite; 40] = [];
            // memcpy(sprites, &ram.data[OAM_BASE], 40 * sizeof(Sprite));
            // for sprite in sprites.iter() {
            for (let n = 0; n < 40; n++) {
                const sprite = new Sprite(
                    this.cpu.ram.get(Mem.OamBase + 4 * n + 0),
                    this.cpu.ram.get(Mem.OamBase + 4 * n + 1),
                    this.cpu.ram.get(Mem.OamBase + 4 * n + 2),
                    this.cpu.ram.get(Mem.OamBase + 4 * n + 3),
                );

                if (sprite.is_live()) {
                    const palette = sprite.palette ? this.obp1 : this.obp0;
                    // printf("Drawing sprite %d (from %04X) at %d,%d\n", tile_id, OAM_BASE + (sprite_id * 4) + 0, x, y);
                    const xy: SDL_Point = {
                        x: sprite.x - 8,
                        y: sprite.y - 16,
                    };
                    this.paint_tile(
                        sprite.tile_id,
                        xy,
                        palette,
                        sprite.x_flip,
                        sprite.y_flip,
                    );

                    if (dbl) {
                        xy.y = sprite.y - 8;
                        this.paint_tile(
                            sprite.tile_id + 1,
                            xy,
                            palette,
                            sprite.x_flip,
                            sprite.y_flip,
                        );
                    }
                }
            }
        }
    }

    paint_tile(
        tile_id: number,
        offset: SDL_Point,
        palette: Array<SDL_Color>,
        flip_x: boolean,
        flip_y: boolean,
    ) {
        for (let y = 0; y < 8; y++) {
            this.paint_tile_line(tile_id, offset, palette, flip_x, flip_y, y);
        }

        if (this.debug) {
            const rect: SDL_Rect = {
                x: offset.x,
                y: offset.y,
                w: 8,
                h: 8,
            };
            const c = gen_hue(tile_id);
            //SDL_SetRenderDrawColor(this.renderer, c.r, c.g, c.b, c.a);
            //SDL_RenderDrawRect(this.renderer, &rect);
        }
    }

    paint_tile_line(
        tile_id: number,
        offset: SDL_Point,
        palette: Array<SDL_Color>,
        flip_x: boolean,
        flip_y: boolean,
        y: number,
    ) {
        const addr: u16 = Mem.TileData + tile_id * 16 + y * 2;
        const low_byte: u8 = this.cpu.ram.get(addr);
        const high_byte: u8 = this.cpu.ram.get(addr + 1);
        for (let x = 0; x < 8; x++) {
            const low_bit = (low_byte >> (7 - x)) & 0x01;
            const high_bit = (high_byte >> (7 - x)) & 0x01;
            const px = (high_bit << 1) | low_bit;
            // pallette #0 = transparent, so don't draw anything
            if (px > 0) {
                const xy: SDL_Point = {
                    x: offset.x + (flip_x ? 7 - x : x),
                    y: offset.y + (flip_y ? 7 - y : y),
                };
                const c = palette[px];
                //SDL_SetRenderDrawColor(this.renderer, c.r, c.g, c.b, c.a);
                //SDL_RenderDrawPoint(this.renderer, xy.x, xy.y);
            }
        }
    }
}

class Sprite {
    y: u8;
    x: u8;
    tile_id: u8;
    flags: u8;

    constructor(y: u8, x: u8, tile_id: u8, flags: u8) {
        this.y = y;
        this.x = x;
        this.tile_id = tile_id;
        this.flags = flags;
    }

    is_live(): boolean {
        return this.x > 0 && this.x < 168 && this.y > 0 && this.y < 160;
    }

    get palette(): boolean {
        return (this.flags & (1 << 4)) != 0;
    }
    get x_flip(): boolean {
        return (this.flags & (1 << 5)) != 0;
    }
    get y_flip(): boolean {
        return (this.flags & (1 << 6)) != 0;
    }
    get behind(): boolean {
        return (this.flags & (1 << 7)) != 0;
    }
}

function gen_hue(n: u8): SDL_Color {
    const region: u8 = Math.floor(n / 43);
    const remainder: u8 = (n - region * 43) * 6;

    const q: u8 = 255 - remainder;
    const t: u8 = remainder;

    switch (region) {
        case 0:
            return { r: 255, g: t, b: 0, a: 0xff };
        case 1:
            return { r: q, g: 255, b: 0, a: 0xff };
        case 2:
            return { r: 0, g: 255, b: t, a: 0xff };
        case 3:
            return { r: 0, g: q, b: 255, a: 0xff };
        case 4:
            return { r: t, g: 0, b: 255, a: 0xff };
        default:
            return { r: 255, g: 0, b: q, a: 0xff };
    }
}
