<?php

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
    public static int $LCY_EQUAL = 1 << 2;
    public static int $MODE_BITS = 1 << 1 | 1 << 0;

    public static int $HBLANK = 0x00;
    public static int $VBLANK = 0x01;
    public static int $OAM = 0x02;
    public static int $DRAWING = 0x03;
}

class Color
{
    public int $a;
    public int $b;
    public int $g;
    public int $r;

    public function __construct(int $r, int $g, int $b, int $a)
    {
        $this->r = $r;
        $this->g = $g;
        $this->b = $b;
        $this->a = $a;
    }
}

function SDL_SetRenderDrawColor(...$x)
{
}

function SDL_RenderClear(...$x)
{
}

function SDL_UpdateTexture(...$x)
{
}

function SDL_RenderCopy(...$x)
{
}

function SDL_RenderPresent(...$x)
{
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

    public function __construct(CPU $cpu, bool $debug, bool $headless)
    {
        $this->cpu = $cpu;
        $this->debug = $debug;
        $this->cycle = 0;

        $this->hw_window = null;
        $this->hw_renderer = null;
        $this->hw_buffer = null;

        $this->renderer = null;
        // FIXME: create a window

        // Colors
        $this->colors[0] = new Color(0x9B, 0xBC, 0x0F, 0xFF);
        $this->colors[1] = new Color(0x8B, 0xAC, 0x0F, 0xFF);
        $this->colors[2] = new Color(0x30, 0x62, 0x30, 0xFF);
        $this->colors[3] = new Color(0x0F, 0x38, 0x0F, 0xFF);
    }

    public function tick(): bool
    {
        $this->cycle++;

        // CPU STOP stops all LCD activity until a button is pressed
        if ($this->cpu->stop) {
            return true;
        }

        // Check if LCD enabled at all
        $lcdc = $this->cpu->ram->get(Mem::$LCDC);
        if (!($lcdc & LCDC::$ENABLED)) {
            // When LCD is re-enabled, LY is 0
            // Does it become 0 as soon as disabled??
            $this->cpu->ram->set(Mem::$LY, 0);
            if (!$this->debug) {
                return true;
            }
        }

        $lx = $this->cycle % 114;
        $ly = floor($this->cycle / 114) % 154;
        $this->cpu->ram->set(Mem::$LY, $ly);

        // LYC compare & interrupt
        if ($this->cpu->ram->get(Mem::$LY) == $this->cpu->ram->get(Mem::$LYC)) {
            if ($this->cpu->ram->get(Mem::$STAT) & Stat::$LYC_INTERRUPT) {
                $this->cpu->interrupt(Interrupt::$STAT);
            }
            $this->cpu->ram->_or(Mem::$STAT, Stat::$LCY_EQUAL);
        } else {
            $this->cpu->ram->_and(Mem::$STAT, ~Stat::$LCY_EQUAL);
        }

        // Set mode
        if ($lx == 0 && $ly < 144) {
            $this->cpu->ram->set(Mem::$STAT, ($this->cpu->ram->get(Mem::$STAT) & ~Stat::$MODE_BITS) | Stat::$OAM);
            if ($this->cpu->ram->get(Mem::$STAT) & Stat::$OAM_INTERRUPT) {
                $this->cpu->interrupt(Interrupt::$STAT);
            }
        } elseif ($lx == 20 && $ly < 144) {
            $this->cpu->ram->set(Mem::$STAT, ($this->cpu->ram->get(Mem::$STAT) & ~Stat::$MODE_BITS) | Stat::$DRAWING);
            if ($ly == 0) {
                // TODO: how often should we update palettes?
                // Should every pixel reference them directly?
                $this->update_palettes();
                // TODO: do we need to clear if we write every pixel?
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
                    SDL_RenderClear($this->hw_renderer);
                    SDL_RenderCopy($this->hw_renderer, $this->hw_buffer, null, null);
                    SDL_RenderPresent($this->hw_renderer);
                }
            }
        } elseif ($lx == 63 && $ly < 144) {
            $this->cpu->ram->set(Mem::$STAT, ($this->cpu->ram->get(Mem::$STAT) & ~Stat::$MODE_BITS) | Stat::$HBLANK);
            if ($this->cpu->ram->get(Mem::$STAT) & Stat::$HBLANK_INTERRUPT) {
                $this->cpu->interrupt(Interrupt::$STAT);
            }
        } elseif ($lx == 0 && $ly == 144) {
            $this->cpu->ram->set(Mem::$STAT, ($this->cpu->ram->get(Mem::$STAT) & ~Stat::$MODE_BITS) | Stat::$VBLANK);
            if ($this->cpu->ram->get(Mem::$STAT) & Stat::$VBLANK_INTERRUPT) {
                $this->cpu->interrupt(Interrupt::$STAT);
            }
            $this->cpu->interrupt(Interrupt::$VBLANK);
        }

        return true;
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
        // FIXME
    }

    public function draw_line(int $y)
    {
        // FIXME
    }
}
