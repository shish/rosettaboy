from sdl2 import *
from typing import NamedTuple
from .consts import *
from .cpu import CPU

SCALE = 2


class LCDC:
    ENABLED = 1 << 7
    WINDOW_MAP = 1 << 6
    WINDOW_ENABLED = 1 << 5
    DATA_SRC = 1 << 4
    BG_MAP = 1 << 3
    OBJ_SIZE = 1 << 2
    OBJ_ENABLED = 1 << 1
    BG_WIN_ENABLED = 1 << 0


class Stat:
    LYC_INTERRUPT = 1 << 6
    OAM_INTERRUPT = 1 << 5
    VBLANK_INTERRUPT = 1 << 4
    HBLANK_INTERRUPT = 1 << 3
    LCY_EQUAL = 1 << 2
    MODE_BITS = 1 << 1 | 1 << 0

    HBLANK = 0x00
    VBLANK = 0x01
    OAM = 0x02
    DRAWING = 0x03


class Sprite(NamedTuple):
    y: int
    x: int
    tile_id: int
    flags: int

    def is_live(self):
        return self.x > 0 and self.x < 168 and self.y > 0 and self.y < 160

    @property
    def palette(self) -> bool:
        return self.flags & (1 << 3)

    @property
    def x_flip(self) -> bool:
        return self.flags & (1 << 3)

    @property
    def y_flip(self) -> bool:
        return self.flags & (1 << 3)

    @property
    def behind(self) -> bool:
        return self.flags & (1 << 3)


rmask = 0x000000FF
gmask = 0x0000FF00
bmask = 0x00FF0000
amask = 0xFF000000


class GPU:
    def __init__(self, cpu: CPU, debug: bool = False, headless: bool = False) -> None:
        self.cpu = cpu
        self.headless = headless
        self.debug = debug
        self.cycle = 0
        self.title = "RosettaBoy - " + (cpu.ram.cart.name or "<corrupt>")

        # Window
        size = (160, 144)
        if self.debug:
            size = (
                160 + 256,
                144,
            )

        if not headless:
            SDL_InitSubSystem(SDL_INIT_VIDEO)
            self.hw_window = SDL_CreateWindow(
                self.title.encode("utf8"),  # window title
                SDL_WINDOWPOS_UNDEFINED,  # initial x position
                SDL_WINDOWPOS_UNDEFINED,  # initial y position
                size[0] * SCALE,  # width, in pixels
                size[1] * SCALE,  # height, in pixels
                SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE,  # flags - see below
            )
            self.hw_renderer = SDL_CreateRenderer(self.hw_window, -1, 0)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, b"nearest")  # vs "linear"
            SDL_RenderSetLogicalSize(self.hw_renderer, size[0], size[1])
            self.hw_buffer = SDL_CreateTexture(
                self.hw_renderer,
                SDL_PIXELFORMAT_ABGR8888,
                SDL_TEXTUREACCESS_STREAMING,
                size[0],
                size[1],
            )
        else:
            self.hw_window = None
            self.hw_renderer = None
            self.hw_buffer = None

        self.buffer: SDL_Surface = SDL_CreateRGBSurface(
            0, size[0], size[1], 32, rmask, gmask, bmask, amask
        )
        self.renderer: SDL_Renderer = SDL_CreateSoftwareRenderer(self.buffer)

        # Colors
        self.colors = [
            SDL_Color(r=0x9B, g=0xBC, b=0x0F, a=0xFF),
            SDL_Color(r=0x8B, g=0xAC, b=0x0F, a=0xFF),
            SDL_Color(r=0x30, g=0x62, b=0x30, a=0xFF),
            SDL_Color(r=0x0F, g=0x38, b=0x0F, a=0xFF),
        ]
        # printf("SDL_Init failed: %s\n", SDL_GetError())

    #    GPU.~GPU():
    #        SDL_FreeSurface(self.buffer)
    #        if(self.hw_window) SDL_DestroyWindow(self.hw_window)
    #        SDL_Quit()

    def tick(self) -> bool:
        self.cycle += 1

        # CPU STOP stops all LCD activity until a button is pressed
        if self.cpu.stop:
            return True

        # Check if LCD enabled at all
        lcdc = self.cpu.ram[Mem.LCDC]
        if not (lcdc & LCDC.ENABLED):
            # When LCD is re-enabled, LY is 0
            # Does it become 0 as soon as disabled??
            self.cpu.ram[Mem.LY] = 0
            if not self.debug:
                return True

        lx = self.cycle % 114
        ly = (self.cycle // 114) % 154
        self.cpu.ram[Mem.LY] = ly

        # LYC compare & interrupt
        if self.cpu.ram[Mem.LY] == self.cpu.ram[Mem.LYC]:
            if self.cpu.ram[Mem.STAT] & Stat.LYC_INTERRUPT:
                self.cpu.interrupt(Interrupt.STAT)

            self.cpu.ram[Mem.STAT] |= Stat.LCY_EQUAL
        else:
            self.cpu.ram[Mem.STAT] &= ~Stat.LCY_EQUAL

        # Set mode
        if lx == 0 and ly < 144:
            self.cpu.ram[Mem.STAT] = (
                self.cpu.ram[Mem.STAT] & ~Stat.MODE_BITS
            ) | Stat.OAM

            if self.cpu.ram[Mem.STAT] & Stat.OAM_INTERRUPT:
                self.cpu.interrupt(Interrupt.STAT)

        elif lx == 20 and ly < 144:
            self.cpu.ram[Mem.STAT] = (
                self.cpu.ram[Mem.STAT] & ~Stat.MODE_BITS
            ) | Stat.DRAWING

            if ly == 0:
                # TODO: how often should we update palettes?
                # Should every pixel reference them directly?
                self.update_palettes()
                # TODO: do we need to clear if we write every pixel?
                c = self.bgp[0]
                SDL_SetRenderDrawColor(self.renderer, c.r, c.g, c.b, c.a)
                SDL_RenderClear(self.renderer)

            self.draw_line(ly)
            if ly == 143:
                if self.debug:
                    self.draw_debug()

                if self.hw_renderer:
                    SDL_UpdateTexture(
                        self.hw_buffer,
                        None,
                        self.buffer.contents.pixels,
                        self.buffer.contents.pitch,
                    )
                    SDL_RenderClear(self.hw_renderer)
                    SDL_RenderCopy(self.hw_renderer, self.hw_buffer, None, None)
                    SDL_RenderPresent(self.hw_renderer)

        elif lx == 63 and ly < 144:
            self.cpu.ram[Mem.STAT] = (
                self.cpu.ram[Mem.STAT] & ~Stat.MODE_BITS
            ) | Stat.HBLANK

            if self.cpu.ram[Mem.STAT] & Stat.HBLANK_INTERRUPT:
                self.cpu.interrupt(Interrupt.STAT)

        elif lx == 0 and ly == 144:
            self.cpu.ram[Mem.STAT] = (
                self.cpu.ram[Mem.STAT] & ~Stat.MODE_BITS
            ) | Stat.VBLANK

            if self.cpu.ram[Mem.STAT] & Stat.VBLANK_INTERRUPT:
                self.cpu.interrupt(Interrupt.STAT)

            self.cpu.interrupt(Interrupt.VBLANK)

        return True

    def update_palettes(self) -> None:
        raw_bgp = self.cpu.ram[Mem.BGP]
        self.bgp = [
            self.colors[(raw_bgp >> 0) & 0x3],
            self.colors[(raw_bgp >> 2) & 0x3],
            self.colors[(raw_bgp >> 4) & 0x3],
            self.colors[(raw_bgp >> 6) & 0x3],
        ]

        raw_obp0 = self.cpu.ram[Mem.OBP0]
        self.obp0 = [
            self.colors[(raw_obp0 >> 0) & 0x3],
            self.colors[(raw_obp0 >> 2) & 0x3],
            self.colors[(raw_obp0 >> 4) & 0x3],
            self.colors[(raw_obp0 >> 6) & 0x3],
        ]

        raw_obp1 = self.cpu.ram[Mem.OBP1]
        self.obp1 = [
            self.colors[(raw_obp1 >> 0) & 0x3],
            self.colors[(raw_obp1 >> 2) & 0x3],
            self.colors[(raw_obp1 >> 4) & 0x3],
            self.colors[(raw_obp1 >> 6) & 0x3],
        ]

    def draw_debug(self) -> None:
        lcdc = self.cpu.ram[Mem.LCDC]

        # Tile data
        tile_display_width = 32
        for tile_id in range(0, 384):
            xy = SDL_Point(
                x=160 + (tile_id % tile_display_width) * 8,
                y=(tile_id // tile_display_width) * 8,
            )

            self.paint_tile(tile_id, xy, self.bgp, False, False)

        # Background scroll border
        if lcdc & LCDC.BG_WIN_ENABLED:
            rect = SDL_Rect(x=0, y=0, w=160, h=144)
            SDL_SetRenderDrawColor(self.renderer, 255, 0, 0, 0xFF)
            SDL_RenderDrawRect(self.renderer, rect)

        # Window tiles
        if lcdc & LCDC.WINDOW_ENABLED:
            wnd_y = self.cpu.ram[Mem.WY]
            wnd_x = self.cpu.ram[Mem.WX]
            rect = SDL_Rect(x=wnd_x - 7, y=wnd_y, w=160, h=144)
            SDL_SetRenderDrawColor(self.renderer, 0, 0, 255, 0xFF)
            SDL_RenderDrawRect(self.renderer, rect)

    def draw_line(self, ly: int) -> None:
        lcdc = self.cpu.ram[Mem.LCDC]

        # Background tiles
        if lcdc & LCDC.BG_WIN_ENABLED:
            scroll_y = self.cpu.ram[Mem.SCY]
            scroll_x = self.cpu.ram[Mem.SCX]
            tile_offset = not (lcdc & LCDC.DATA_SRC)
            background_map = Mem.MAP_1 if (lcdc & LCDC.BG_MAP) else Mem.MAP_0

            if self.debug:
                xy = SDL_Point(x=256 - scroll_x, y=ly)
                SDL_SetRenderDrawColor(self.renderer, 255, 0, 0, 0xFF)
                SDL_RenderDrawPoint(self.renderer, xy.x, xy.y)

            y_in_bgmap = (ly - scroll_y) & 0xFF  # % 256
            tile_y = y_in_bgmap // 8
            tile_sub_y = y_in_bgmap % 8

            for tile_x in range(scroll_x // 8, scroll_x // 8 + 21):
                tile_id = self.cpu.ram[
                    background_map + (tile_y % 32) * 32 + (tile_x % 32)
                ]
                if tile_offset and tile_id < 0x80:
                    tile_id += 0x100

                xy = SDL_Point(
                    x=((tile_x * 8 - scroll_x) + 8) % 256 - 8,
                    y=((tile_y * 8 - scroll_y) + 8) % 256 - 8,
                )

                self.paint_tile_line(tile_id, xy, self.bgp, False, False, tile_sub_y)

        # Window tiles
        if lcdc & LCDC.WINDOW_ENABLED:
            wnd_y = self.cpu.ram[Mem.WY]
            wnd_x = self.cpu.ram[Mem.WX]
            tile_offset = not (lcdc & LCDC.DATA_SRC)
            window_map = Mem.MAP_1 if (lcdc & LCDC.WINDOW_MAP) else Mem.MAP_0

            # blank out the background
            rect = SDL_Rect(
                x=wnd_x - 7,
                y=wnd_y,
                w=160,
                h=144,
            )

            c = self.bgp[0]
            SDL_SetRenderDrawColor(self.renderer, c.r, c.g, c.b, c.a)
            SDL_RenderFillRect(self.renderer, rect)

            y_in_bgmap = ly - wnd_y
            tile_y = y_in_bgmap // 8
            tile_sub_y = y_in_bgmap % 8

            for tile_x in range(0, 20):
                tile_id = self.cpu.ram[window_map + tile_y * 32 + tile_x]
                if tile_offset and tile_id < 0x80:
                    tile_id += 0x100

                xy = SDL_Point(
                    x=tile_x * 8 + wnd_x - 7,
                    y=tile_y * 8 + wnd_y,
                )

                self.paint_tile_line(tile_id, xy, self.bgp, False, False, tile_sub_y)

        # Sprites
        if lcdc & LCDC.OBJ_ENABLED:
            dbl = lcdc & LCDC.OBJ_SIZE

            # TODO: sorted by x
            # auto sprites: [Sprite 40] = []
            # memcpy(sprites, &ram.data[OAM_BASE], 40 * sizeof(Sprite))
            # for sprite in sprites.iter():
            for n in range(0, 40):
                sprite = Sprite(
                    y=self.cpu.ram[Mem.OAM_BASE + 4 * n + 0],
                    x=self.cpu.ram[Mem.OAM_BASE + 4 * n + 1],
                    tile_id=self.cpu.ram[Mem.OAM_BASE + 4 * n + 2],
                    flags=self.cpu.ram[Mem.OAM_BASE + 4 * n + 3],
                )

                if sprite.is_live():
                    palette = self.obp1 if sprite.palette else self.obp0
                    # printf("Drawing sprite %d (from %04X) at %d,%d\n", tile_id, OAM_BASE + (sprite_id * 4) + 0, x, y)
                    xy = SDL_Point(
                        x=sprite.x - 8,
                        y=sprite.y - 16,
                    )

                    self.paint_tile(
                        sprite.tile_id, xy, palette, sprite.x_flip, sprite.y_flip
                    )

                    if dbl:
                        xy.y = sprite.y - 8
                        self.paint_tile(
                            sprite.tile_id + 1,
                            xy,
                            palette,
                            sprite.x_flip,
                            sprite.y_flip,
                        )

    def paint_tile(
        self,
        tile_id: int,
        offset: SDL_Point,
        palette: SDL_Color,
        flip_x: bool,
        flip_y: bool,
    ) -> None:
        for y in range(0, 8):
            self.paint_tile_line(tile_id, offset, palette, flip_x, flip_y, y)

        if self.debug:
            rect = SDL_Rect(
                x=offset.x,
                y=offset.y,
                w=8,
                h=8,
            )

            c = gen_hue(tile_id)
            SDL_SetRenderDrawColor(self.renderer, c.r, c.g, c.b, c.a)
            SDL_RenderDrawRect(self.renderer, rect)

    def paint_tile_line(
        self,
        tile_id: int,
        offset: SDL_Point,
        palette: SDL_Color,
        flip_x: bool,
        flip_y: bool,
        y: int,
    ) -> None:
        addr = Mem.TILE_DATA + tile_id * 16 + y * 2
        low_byte = self.cpu.ram[addr]
        high_byte = self.cpu.ram[addr + 1]
        for x in range(0, 8):
            low_bit = (low_byte >> (7 - x)) & 0x01
            high_bit = (high_byte >> (7 - x)) & 0x01
            px = (high_bit << 1) | low_bit
            # pallette #0 = transparent, so don't draw anything
            if px > 0:
                xy = SDL_Point(
                    x=offset.x + (7 - x if flip_x else x),
                    y=offset.y + (7 - y if flip_y else y),
                )

                c = palette[px]
                SDL_SetRenderDrawColor(self.renderer, c.r, c.g, c.b, c.a)
                SDL_RenderDrawPoint(self.renderer, xy.x, xy.y)


def gen_hue(n: int) -> SDL_Color:
    region = n // 43
    remainder = (n - (region * 43)) * 6

    q = 255 - remainder
    t = remainder

    if region == 0:
        return SDL_Color(r=255, g=t, b=0, a=0xFF)
    if region == 1:
        return SDL_Color(r=q, g=255, b=0, a=0xFF)
    if region == 2:
        return SDL_Color(r=0, g=255, b=t, a=0xFF)
    if region == 3:
        return SDL_Color(r=0, g=q, b=255, a=0xFF)
    if region == 4:
        return SDL_Color(r=t, g=0, b=255, a=0xFF)
    return SDL_Color(r=255, g=0, b=q, a=0xFF)
