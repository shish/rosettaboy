<?php

const SCALE = 2;

class LCDC
{
    public static int $ENABLED = 1 << 7;
    public static int $WINDOW_MAP = 1 << 6;
    public static int $WINDOW_ENABLED = 1 << 5;
    public static int $DATA_SRC = 1 << 4;
    public static int $BG_MAP = 1 << 3;
    public static int $OBJ_SIZE = 1 << 2;
    public static int $OBJ_ENABLED = 1 << 1;
    public static int $BG_WIN_ENABLED = 1 << 0;
}

class Stat
{
    public static int $LYC_INTERRUPT = 1 << 6;
    public static int $OAM_INTERRUPT = 1 << 5;
    public static int $VBLANK_INTERRUPT = 1 << 4;
    public static int $HBLANK_INTERRUPT = 1 << 3;
    public static int $LYC_EQUAL = 1 << 2;
    public static int $MODE_BITS = 1 << 1 | 1 << 0;

    public static int $HBLANK = 0x00;
    public static int $VBLANK = 0x01;
    public static int $OAM = 0x02;
    public static int $DRAWING = 0x03;
}


class GPU
{
    private int $cycle;
    private bool $debug;
    private CPU $cpu;

    private $renderer;
    private $buffer;
    private $hw_buffer;
    private $hw_renderer;
    private $hw_window;
    private array $colors;
    private array $bgp;
    private array $obp0;
    private array $obp1;

    public function __construct(CPU $cpu, bool $debug, bool $headless)
    {
        $rmask = 0x000000ff;
        $gmask = 0x0000ff00;
        $bmask = 0x00ff0000;
        $amask = 0xff000000;

        $this->cpu = $cpu;
        $this->debug = $debug;
        $this->cycle = 0;

        $this->hw_window = null;
        $this->hw_renderer = null;
        $this->hw_buffer = null;

        $this->renderer = null;

        $w = 160;
        $h = 144;
        if ($this->debug) {
            $w = 160 + 256;
            $h = 144;
        }
        if (!$headless) {
            SDL_InitSubSystem(SDL_INIT_VIDEO);
            $this->hw_window = SDL_CreateWindow(
                sprintf("RosettaBoy - %s", "FIXME"),            // window title
                SDL_WINDOWPOS_UNDEFINED,                        // initial x position
                SDL_WINDOWPOS_UNDEFINED,                        // initial y position
                $w * SCALE,                                     // width, in pixels
                $h * SCALE,                                     // height, in pixels
                SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE // flags - see below
            );
            $this->hw_renderer = SDL_CreateRenderer($this->hw_window, -1, 0);
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "nearest"); // vs "linear"
            SDL_RenderSetLogicalSize($this->hw_renderer, $w, $h);
            $this->hw_buffer =
                SDL_CreateTexture($this->hw_renderer, SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STREAMING, $w, $h);
        }
        $this->buffer = SDL_CreateRGBSurface(0, $w, $h, 32, $rmask, $gmask, $bmask, $amask);
        $this->renderer = SDL_CreateSoftwareRenderer($this->buffer);

        // Colors
        $this->colors[0] = new SDL_Color(0x9B, 0xBC, 0x0F, 0xFF);
        $this->colors[1] = new SDL_Color(0x8B, 0xAC, 0x0F, 0xFF);
        $this->colors[2] = new SDL_Color(0x30, 0x62, 0x30, 0xFF);
        $this->colors[3] = new SDL_Color(0x0F, 0x38, 0x0F, 0xFF);
    }

    public function tick(): void
    {
        $this->cycle++;

        // CPU STOP stops all LCD activity until a button is pressed
        if ($this->cpu->stop) {
            return;
        }

        // Check if LCD enabled at all
        $lcdc = $this->cpu->ram->get(Mem::$LCDC);
        if (!($lcdc & LCDC::$ENABLED)) {
            // When LCD is re-enabled, LY is 0
            // Does it become 0 as soon as disabled??
            $this->cpu->ram->set(Mem::$LY, 0);
            if (!$this->debug) {
                return;
            }
        }

        $lx = $this->cycle % 114;
        $ly = floor($this->cycle / 114) % 154;
        $this->cpu->ram->set(Mem::$LY, $ly);

        $stat = $this->cpu->ram->get(Mem::$STAT);
        $stat &= ~Stat::$MODE_BITS;
        $stat &= ~Stat::$LYC_EQUAL;

        // LYC compare & interrupt
        if ($ly == $this->cpu->ram->get(Mem::$LYC)) {
            $stat |= Stat::$LYC_EQUAL;
            if ($stat & Stat::$LYC_INTERRUPT) {
                $this->cpu->interrupt(Interrupt::STAT);
            }
        }

        // Set mode
        if ($lx == 0 && $ly < 144) {
            $stat |= Stat::$OAM;
            if ($stat & Stat::$OAM_INTERRUPT) {
                $this->cpu->interrupt(Interrupt::STAT);
            }
        } elseif ($lx == 20 && $ly < 144) {
            $stat |= Stat::$DRAWING;
            if ($ly == 0) {
                // TODO: how often should we update palettes?
                // Should every pixel reference them directly?
                $this->update_palettes();
                $c = $this->bgp[0];
                SDL_SetRenderDrawColor($this->renderer, $c->r, $c->g, $c->b, $c->a);
                SDL_RenderClear($this->renderer);
            }
            $this->draw_line($ly);
            if ($ly == 143) {
                if ($this->debug) {
                    $this->draw_debug();
                }
                if ($this->hw_renderer) {
                    SDL_UpdateTexture($this->hw_buffer, null, $this->buffer->pixels, $this->buffer->pitch);
                    SDL_RenderCopy($this->hw_renderer, $this->hw_buffer, null, null);
                    SDL_RenderPresent($this->hw_renderer);
                }
            }
        } elseif ($lx == 63 && $ly < 144) {
            $stat |= Stat::$HBLANK;
            if ($stat & Stat::$HBLANK_INTERRUPT) {
                $this->cpu->interrupt(Interrupt::STAT);
            }
        } elseif ($lx == 0 && $ly == 144) {
            $stat |= Stat::$VBLANK;
            if ($stat & Stat::$VBLANK_INTERRUPT) {
                $this->cpu->interrupt(Interrupt::STAT);
            }
            $this->cpu->interrupt(Interrupt::VBLANK);
        }
        $this->cpu->ram->set(Mem::$STAT, $stat);
    }

    public function update_palettes()
    {
        $raw_bgp = $this->cpu->ram->get(Mem::$BGP);
        $this->bgp[0] = $this->colors[($raw_bgp >> 0) & 0x3];
        $this->bgp[1] = $this->colors[($raw_bgp >> 2) & 0x3];
        $this->bgp[2] = $this->colors[($raw_bgp >> 4) & 0x3];
        $this->bgp[3] = $this->colors[($raw_bgp >> 6) & 0x3];

        $raw_obp0 = $this->cpu->ram->get(Mem::$OBP0);
        $this->obp0[0] = $this->colors[($raw_obp0 >> 0) & 0x3];
        $this->obp0[1] = $this->colors[($raw_obp0 >> 2) & 0x3];
        $this->obp0[2] = $this->colors[($raw_obp0 >> 4) & 0x3];
        $this->obp0[3] = $this->colors[($raw_obp0 >> 6) & 0x3];

        $raw_obp1 = $this->cpu->ram->get(Mem::$OBP1);
        $this->obp1[0] = $this->colors[($raw_obp1 >> 0) & 0x3];
        $this->obp1[1] = $this->colors[($raw_obp1 >> 2) & 0x3];
        $this->obp1[2] = $this->colors[($raw_obp1 >> 4) & 0x3];
        $this->obp1[3] = $this->colors[($raw_obp1 >> 6) & 0x3];
    }

    public function draw_debug()
    {
        $LCDC = $this->cpu->ram->get(Mem::$LCDC);

        // Tile data
        $tile_display_width = 32;
        for ($tile_id = 0; $tile_id < 384; $tile_id++) {
            $xy = new SDL_Point(
                160 + ($tile_id % $tile_display_width) * 8,
                floor($tile_id / $tile_display_width) * 8,
            );
            $this->paint_tile($tile_id, $xy, $this->bgp, false, false);
        }

        // Background scroll border
        if ($LCDC & LCDC::$BG_WIN_ENABLED) {
            $rect = new SDL_Rect(0, 0, 160, 144);
            SDL_SetRenderDrawColor($this->renderer, 255, 0, 0, 0xFF);
            SDL_RenderDrawRect($this->renderer, $rect);
        }

        // Window tiles
        if ($LCDC & LCDC::$WINDOW_ENABLED) {
            $wnd_y = $this->cpu->ram->get(Mem::$WY);
            $wnd_x = $this->cpu->ram->get(Mem::$WX);
            $rect = new SDL_Rect($wnd_x - 7, $wnd_y, 160, 144);
            SDL_SetRenderDrawColor($this->renderer, 0, 0, 255, 0xFF);
            SDL_RenderDrawRect($this->renderer, $rect);
        }
    }

    public function draw_line(int $ly)
    {
        $lcdc = $this->cpu->ram->get(Mem::$LCDC);

        // Background tiles
        if ($lcdc & LCDC::$BG_WIN_ENABLED) {
            $scroll_y = $this->cpu->ram->get(Mem::$SCY);
            $scroll_x = $this->cpu->ram->get(Mem::$SCX);
            $tile_offset = !($lcdc & LCDC::$DATA_SRC);
            $tile_map = ($lcdc & LCDC::$BG_MAP) ? Mem::$MAP_1 : Mem::$MAP_0;

            if ($this->debug) {
                $xy = new SDL_Point(256 - $scroll_x, $ly);
                SDL_SetRenderDrawColor($this->renderer, 255, 0, 0, 0xFF);
                SDL_RenderDrawPoint($this->renderer, $xy->x, $xy->y);
            }

            $y_in_bgmap = ($ly + $scroll_y) % 256;
            $tile_y = floor($y_in_bgmap / 8);
            $tile_sub_y = $y_in_bgmap % 8;

            for ($lx = 0; $lx <= 160; $lx += 8) {
                $x_in_bgmap = ($lx + $scroll_x) % 256;
                $tile_x = floor($x_in_bgmap / 8);
                $tile_sub_x = $x_in_bgmap % 8;

                $tile_id = $this->cpu->ram->get($tile_map + $tile_y * 32 + $tile_x);
                if ($tile_offset && $tile_id < 0x80) {
                    $tile_id += 0x100;
                }
                $xy = new SDL_Point(
                    $lx - $tile_sub_x,
                    $ly - $tile_sub_y,
                );
                $this->paint_tile_line($tile_id, $xy, $this->bgp, false, false, $tile_sub_y);
            }
        }

        // Window tiles
        if ($lcdc & LCDC::$WINDOW_ENABLED) {
            $wnd_y = $this->cpu->ram->get(Mem::$WY);
            $wnd_x = $this->cpu->ram->get(Mem::$WX);
            $tile_offset = !($lcdc & LCDC::$DATA_SRC);
            $tile_map = ($lcdc & LCDC::$WINDOW_MAP) ? Mem::$MAP_1 : Mem::$MAP_0;

            // blank out the background
            $rect = new SDL_Rect(
                $wnd_x - 7,
                $wnd_y,
                160,
                144,
            );
            $c = $this->bgp[0];
            SDL_SetRenderDrawColor($this->renderer, $c->r, $c->g, $c->b, $c->a);
            SDL_RenderFillRect($this->renderer, $rect);

            $y_in_bgmap = $ly - $wnd_y;
            $tile_y = $y_in_bgmap / 8;
            $tile_sub_y = $y_in_bgmap % 8;

            for ($tile_x = 0; $tile_x < 20; $tile_x++) {
                $tile_id = $this->cpu->ram->get($tile_map + $tile_y * 32 + $tile_x);
                if ($tile_offset && $tile_id < 0x80) {
                    $tile_id += 0x100;
                }
                $xy = new SDL_Point(
                    $tile_x * 8 + $wnd_x - 7,
                    $tile_y * 8 + $wnd_y,
                );
                $this->paint_tile_line($tile_id, $xy, $this->bgp, false, false, $tile_sub_y);
            }
        }

        // Sprites
        if ($lcdc & LCDC::$OBJ_ENABLED) {
            $dbl = $lcdc & LCDC::$OBJ_SIZE;

            // TODO: sorted by x
            // $sprites: [Sprite; 40] = [];
            // memcpy(sprites, &ram.data[OAM_BASE], 40 * sizeof(Sprite));
            // for sprite in sprites.iter() {
            for ($n = 0; $n < 40; $n++) {
                $sprite = new Sprite(
                    $this->cpu->ram->get(Mem::$OAM_BASE + 4 * $n + 0),
                    $this->cpu->ram->get(Mem::$OAM_BASE + 4 * $n + 1),
                    $this->cpu->ram->get(Mem::$OAM_BASE + 4 * $n + 2),
                    $this->cpu->ram->get(Mem::$OAM_BASE + 4 * $n + 3),
                );

                if ($sprite->is_live()) {
                    $palette = $sprite->palette ? $this->obp1 : $this->obp0;
                    // printf("Drawing sprite %d (from %04X) at %d,%d\n", tile_id, OAM_BASE + (sprite_id * 4) + 0, x, y);
                    $xy = new SDL_Point(
                        $sprite->x - 8,
                        $sprite->y - 16,
                    );
                    $this->paint_tile($sprite->tile_id, $xy, $palette, $sprite->x_flip, $sprite->y_flip);

                    if ($dbl) {
                        $xy->y = $sprite->y - 8;
                        $this->paint_tile($sprite->tile_id + 1, $xy, $palette, $sprite->x_flip, $sprite->y_flip);
                    }
                }
            }
        }
    }

    public function paint_tile(int $tile_id, SDL_Point $offset, array $palette, bool $flip_x, bool $flip_y)
    {
        for ($y = 0; $y < 8; $y++) {
            $this->paint_tile_line($tile_id, $offset, $palette, $flip_x, $flip_y, $y);
        }

        if ($this->debug) {
            $rect = new SDL_Rect(
                $offset->x,
                $offset->y,
                8,
                8,
            );
            $c = gen_hue($tile_id);
            SDL_SetRenderDrawColor($this->renderer, $c->r, $c->g, $c->b, $c->a);
            SDL_RenderDrawRect($this->renderer, $rect);
        }
    }

    public function paint_tile_line(int $tile_id, SDL_Point $offset, array $palette, bool $flip_x, bool $flip_y, int $y)
    {
        $addr = (Mem::$TILE_DATA + $tile_id * 16 + $y * 2);
        $low_byte = $this->cpu->ram->get($addr);
        $high_byte = $this->cpu->ram->get($addr + 1);
        for ($x = 0; $x < 8; $x++) {
            $low_bit = ($low_byte >> (7 - $x)) & 0x01;
            $high_bit = ($high_byte >> (7 - $x)) & 0x01;
            $px = ($high_bit << 1) | $low_bit;
            // pallette #0 = transparent, so don't draw anything
            if ($px > 0) {
                $xy = new SDL_Point(
                    $offset->x + ($flip_x ? 7 - $x : $x),
                    $offset->y + ($flip_y ? 7 - $y : $y),
                );
                $c = $palette[$px];
                SDL_SetRenderDrawColor($this->renderer, $c->r, $c->g, $c->b, $c->a);
                SDL_RenderDrawPoint($this->renderer, $xy->x, $xy->y);
            }
        }
    }
}

function gen_hue(int $n): SDL_Color
{
    $region = floor($n / 43);
    $remainder = ($n - ($region * 43)) * 6;

    $q = 255 - $remainder;
    $t = $remainder;

    switch ($region) {
        case 0: return new SDL_Color(255, $t, 0, 0xFF);
        case 1: return new SDL_Color($q, 255, 0, 0xFF);
        case 2: return new SDL_Color(0, 255, $t, 0xFF);
        case 3: return new SDL_Color(0, $q, 255, 0xFF);
        case 4: return new SDL_Color($t, 0, 255, 0xFF);
        default: return new SDL_Color(255, 0, $q, 0xFF);
    }
}

class Sprite
{
    public int $x;
    public int $y;
    public int $tile_id;
    //public int $flags;
    public bool $palette;
    public bool $x_flip;
    public bool $y_flip;
    public bool $behind;

    public function __construct(int $y, int $x, int $tile_id, int $flags)
    {
        $this->y = $y;
        $this->x = $x;
        $this->tile_id = $tile_id;
        $this->palette = ($flags & 0x8) > 0;
        $this->x_flip = ($flags & 0x4) > 0;
        $this->y_flip = ($flags & 0x2) > 0;
        $this->behind = ($flags & 0x1) > 0;
    }

    public function is_live(): bool
    {
        return $this->x > 0 && $this->x < 168 && $this->y > 0 && $this->y < 160;
    }
}
