import cython

if not cython.compiled:
    import sdl2

import typing as t

if cython.compiled:
    from cython.cimports.cpython.mem import PyMem_Malloc, PyMem_Free
else:
    from .consts import *
    from .cpu import CPU

SCALE = 2


def make_SDL_Rect(x, y, w, h):
    if cython.compiled:
        q: cython.pointer(sdl2.SDL_Rect)
        q = cython.cast(
            cython.pointer(sdl2.SDL_Rect), PyMem_Malloc(cython.sizeof(sdl2.SDL_Rect))
        )
        q.x, q.y, q.w, q.h = x, y, w, h
    else:
        q = sdl2.SDL_Rect(x=x, y=y, w=w, h=h)
    return q


def make_SDL_Point(x, y):
    if cython.compiled:
        p: sdl2.SDL_Point
        p.x, p.y = x, y
    else:
        p = sdl2.SDL_Point(x=x, y=y)
    return p


class _LCDC:
    def __init__(self):
        self.ENABLED: u8 = 1 << 7
        self.WINDOW_MAP: u8 = 1 << 6
        self.WINDOW_ENABLED: u8 = 1 << 5
        self.DATA_SRC: u8 = 1 << 4
        self.BG_MAP: u8 = 1 << 3
        self.OBJ_SIZE: u8 = 1 << 2
        self.OBJ_ENABLED: u8 = 1 << 1
        self.BG_WIN_ENABLED: u8 = 1 << 0


LCDC = _LCDC()


class _Stat:
    def __init__(self):
        self.LYC_INTERRUPT: u8 = 1 << 6
        self.OAM_INTERRUPT: u8 = 1 << 5
        self.VBLANK_INTERRUPT: u8 = 1 << 4
        self.HBLANK_INTERRUPT: u8 = 1 << 3
        self.LYC_EQUAL: u8 = 1 << 2
        self.MODE_BITS: u8 = 1 << 1 | 1 << 0

        self.HBLANK: u8 = 0x00
        self.VBLANK: u8 = 0x01
        self.OAM: u8 = 0x02
        self.DRAWING: u8 = 0x03


Stat = _Stat()


class Sprite:
    y: cython.int
    x: cython.int
    tile_id: cython.int
    flags: cython.int

    def __init__(self, *args, **kwargs):
        if not cython.compiled:
            self.__cinit__(*args, **kwargs)

    def __cinit__(
        self, x: cython.int, y: cython.int, tile_id: cython.int, flags: cython.int
    ):
        self.x = x
        self.y = y
        self.tile_id = tile_id
        self.flags = flags

    @staticmethod
    def create(x: cython.int, y: cython.int, tile_id: cython.int, flags: cython.int):
        if cython.compiled:
            return Sprite.__new__(Sprite, x, y, tile_id, flags)
        else:
            return Sprite(x, y, tile_id, flags)

    def is_live(self) -> bool:
        return self.x > 0 and self.x < 168 and self.y > 0 and self.y < 160

    def palette(self) -> bool:
        return self.flags & (1 << 4) != 0

    def x_flip(self) -> bool:
        return self.flags & (1 << 5) != 0

    def y_flip(self) -> bool:
        return self.flags & (1 << 6) != 0

    def behind(self) -> bool:
        return self.flags & (1 << 7) != 0


rmask: t.Final[int] = 0x000000FF
gmask: t.Final[int] = 0x0000FF00
bmask: t.Final[int] = 0x00FF0000
amask: t.Final[int] = 0xFF000000


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
            sdl2.SDL_InitSubSystem(sdl2.SDL_INIT_VIDEO)
            self.hw_window = sdl2.SDL_CreateWindow(
                self.title.encode("utf8"),  # window title
                sdl2.SDL_WINDOWPOS_UNDEFINED,  # initial x position
                sdl2.SDL_WINDOWPOS_UNDEFINED,  # initial y position
                size[0] * SCALE,  # width, in pixels
                size[1] * SCALE,  # height, in pixels
                sdl2.SDL_WINDOW_ALLOW_HIGHDPI
                | sdl2.SDL_WINDOW_RESIZABLE,  # flags - see below
            )
            self.hw_renderer = sdl2.SDL_CreateRenderer(self.hw_window, -1, 0)
            sdl2.SDL_SetHint(
                sdl2.SDL_HINT_RENDER_SCALE_QUALITY, b"nearest"
            )  # vs "linear"
            sdl2.SDL_RenderSetLogicalSize(self.hw_renderer, size[0], size[1])
            self.hw_buffer = sdl2.SDL_CreateTexture(
                self.hw_renderer,
                sdl2.SDL_PixelFormatEnum.SDL_PIXELFORMAT_ABGR8888
                if cython.compiled
                else sdl2.SDL_PIXELFORMAT_ABGR8888,
                sdl2.SDL_TEXTUREACCESS_STREAMING,
                size[0],
                size[1],
            )
        elif not cython.compiled:
            self.hw_window = None
            self.hw_renderer = None
            self.hw_buffer = None

        self.buffer: sdl2.SDL_Surface = sdl2.SDL_CreateRGBSurface(
            0, size[0], size[1], 32, rmask, gmask, bmask, amask
        )
        self.renderer: sdl2.SDL_Renderer = sdl2.SDL_CreateSoftwareRenderer(self.buffer)

        # Colors
        self.colors = [
            sdl2.SDL_Color(r=0x9B, g=0xBC, b=0x0F, a=0xFF),
            sdl2.SDL_Color(r=0x8B, g=0xAC, b=0x0F, a=0xFF),
            sdl2.SDL_Color(r=0x30, g=0x62, b=0x30, a=0xFF),
            sdl2.SDL_Color(r=0x0F, g=0x38, b=0x0F, a=0xFF),
        ]
        # printf("SDL_Init failed: %s\n", sdl2.SDL_GetError())

    #    GPU.~GPU():
    #        sdl2.SDL_FreeSurface(self.buffer)
    #        if(self.hw_window) sdl2.SDL_DestroyWindow(self.hw_window)
    #        sdl2.SDL_Quit()

    def tick(self) -> None:
        self.cycle += 1

        # CPU STOP stops all LCD activity until a button is pressed
        if self.cpu.stop:
            return 0

        # Check if LCD enabled at all
        lcdc = self.cpu.ram.get(Mem.LCDC)
        if not (lcdc & LCDC.ENABLED):
            # When LCD is re-enabled, LY is 0
            # Does it become 0 as soon as disabled??
            self.cpu.ram.set(Mem.LY, 0)
            if not self.debug:
                return 0

        lx = self.cycle % 114
        ly = (self.cycle // 114) % 154
        self.cpu.ram.set(Mem.LY, ly)

        stat: cython.int = self.cpu.ram.get(Mem.STAT)
        stat &= ~Stat.MODE_BITS
        stat &= ~Stat.LYC_EQUAL

        # LYC compare & interrupt
        if ly == self.cpu.ram.get(Mem.LYC):
            stat |= Stat.LYC_EQUAL
            if stat & Stat.LYC_INTERRUPT:
                self.cpu.interrupt(Interrupt.STAT)

        # Set mode
        if lx == 0 and ly < 144:
            stat |= Stat.OAM
            if stat & Stat.OAM_INTERRUPT:
                self.cpu.interrupt(Interrupt.STAT)

        elif lx == 20 and ly < 144:
            stat |= Stat.DRAWING

            if ly == 0:
                # TODO: how often should we update palettes?
                # Should every pixel reference them directly?
                self.update_palettes()
                c = self.bgp[0]
                sdl2.SDL_SetRenderDrawColor(self.renderer, c.r, c.g, c.b, c.a)
                sdl2.SDL_RenderClear(self.renderer)

            self.draw_line(ly)
            if ly == 143:
                if self.debug:
                    self.draw_debug()

                if self.hw_renderer:
                    sdl2.SDL_UpdateTexture(
                        self.hw_buffer,
                        cython.NULL if cython.compiled else None,
                        self.buffer.pixels
                        if cython.compiled
                        else self.buffer.contents.pixels,
                        self.buffer.pitch
                        if cython.compiled
                        else self.buffer.contents.pitch,
                    )
                    sdl2.SDL_RenderCopy(
                        self.hw_renderer,
                        self.hw_buffer,
                        cython.NULL if cython.compiled else None,
                        cython.NULL if cython.compiled else None,
                    )
                    sdl2.SDL_RenderPresent(self.hw_renderer)

        elif lx == 63 and ly < 144:
            stat |= Stat.HBLANK
            if stat & Stat.HBLANK_INTERRUPT:
                self.cpu.interrupt(Interrupt.STAT)

        elif lx == 0 and ly == 144:
            stat |= Stat.VBLANK
            if stat & Stat.VBLANK_INTERRUPT:
                self.cpu.interrupt(Interrupt.STAT)
            self.cpu.interrupt(Interrupt.VBLANK)

        self.cpu.ram.set(Mem.STAT, stat)

    def update_palettes(self) -> None:
        raw_bgp: cython.int = self.cpu.ram.get(Mem.BGP)
        self.bgp = [
            self.colors[(raw_bgp >> 0) & 0x3],
            self.colors[(raw_bgp >> 2) & 0x3],
            self.colors[(raw_bgp >> 4) & 0x3],
            self.colors[(raw_bgp >> 6) & 0x3],
        ]

        raw_obp0: cython.int = self.cpu.ram.get(Mem.OBP0)
        self.obp0 = [
            self.colors[(raw_obp0 >> 0) & 0x3],
            self.colors[(raw_obp0 >> 2) & 0x3],
            self.colors[(raw_obp0 >> 4) & 0x3],
            self.colors[(raw_obp0 >> 6) & 0x3],
        ]

        raw_obp1: cython.int = self.cpu.ram.get(Mem.OBP1)
        self.obp1 = [
            self.colors[(raw_obp1 >> 0) & 0x3],
            self.colors[(raw_obp1 >> 2) & 0x3],
            self.colors[(raw_obp1 >> 4) & 0x3],
            self.colors[(raw_obp1 >> 6) & 0x3],
        ]

    def draw_debug(self) -> None:
        lcdc = self.cpu.ram.get(Mem.LCDC)

        # Tile data
        tile_display_width: cython.int = 32
        tile_id: cython.int
        for tile_id in range(0, 384):
            xy = make_SDL_Point(
                x=160 + (tile_id % tile_display_width) * 8,
                y=(tile_id // tile_display_width) * 8,
            )

            self.paint_tile(tile_id, xy, self.bgp, False, False)

        # Background scroll border
        if lcdc & LCDC.BG_WIN_ENABLED:
            rect = make_SDL_Rect(x=0, y=0, w=160, h=144)
            sdl2.SDL_SetRenderDrawColor(self.renderer, 255, 0, 0, 0xFF)
            sdl2.SDL_RenderDrawRect(self.renderer, rect)
            if cython.compiled:
                PyMem_Free(rect)

        # Window tiles
        if lcdc & LCDC.WINDOW_ENABLED:
            wnd_y = self.cpu.ram.get(Mem.WY)
            wnd_x: cython.int = self.cpu.ram.get(Mem.WX)
            rect = make_SDL_Rect(x=wnd_x - 7, y=wnd_y, w=160, h=144)
            sdl2.SDL_SetRenderDrawColor(self.renderer, 0, 0, 255, 0xFF)
            sdl2.SDL_RenderDrawRect(self.renderer, rect)
            if cython.compiled:
                PyMem_Free(rect)

    def draw_line(self, ly: cython.int) -> None:
        lcdc = self.cpu.ram.get(Mem.LCDC)

        # Background tiles
        if lcdc & LCDC.BG_WIN_ENABLED:
            scroll_y: cython.int = self.cpu.ram.get(Mem.SCY)
            scroll_x: cython.int = self.cpu.ram.get(Mem.SCX)
            tile_offset = not (lcdc & LCDC.DATA_SRC)
            tile_map: cython.int = Mem.MAP_1 if (lcdc & LCDC.BG_MAP) else Mem.MAP_0

            if self.debug:
                xy = make_SDL_Point(x=256 - scroll_x, y=ly)
                sdl2.SDL_SetRenderDrawColor(self.renderer, 255, 0, 0, 0xFF)
                sdl2.SDL_RenderDrawPoint(self.renderer, xy.x, xy.y)

            y_in_bgmap: cython.int = (ly + scroll_y) % 256
            tile_y: cython.int = y_in_bgmap // 8
            tile_sub_y: cython.int = y_in_bgmap % 8

            lx: cython.int
            for lx in range(0, 160 + 1, 8):
                x_in_bgmap: cython.int = (lx + scroll_x) % 256
                tile_x: cython.int = x_in_bgmap // 8
                tile_sub_x: cython.int = x_in_bgmap % 8

                tile_id: cython.int = self.cpu.ram.get(tile_map + tile_y * 32 + tile_x)
                if tile_offset and tile_id < 0x80:
                    tile_id += 0x100

                xy = make_SDL_Point(
                    x=lx - tile_sub_x,
                    y=ly - tile_sub_y,
                )

                self.paint_tile_line(tile_id, xy, self.bgp, False, False, tile_sub_y)

        # Window tiles
        if lcdc & LCDC.WINDOW_ENABLED:
            wnd_y: cython.int = self.cpu.ram.get(Mem.WY)
            wnd_x: cython.int = self.cpu.ram.get(Mem.WX)
            tile_offset = not (lcdc & LCDC.DATA_SRC)
            tile_map = Mem.MAP_1 if (lcdc & LCDC.WINDOW_MAP) else Mem.MAP_0

            # blank out the background
            rect = make_SDL_Rect(
                x=wnd_x - 7,
                y=wnd_y,
                w=160,
                h=144,
            )

            c = self.bgp[0]
            sdl2.SDL_SetRenderDrawColor(self.renderer, c.r, c.g, c.b, c.a)
            sdl2.SDL_RenderFillRect(self.renderer, rect)
            if cython.compiled:
                PyMem_Free(rect)

            y_in_bgmap: cython.int = ly - wnd_y
            tile_y = y_in_bgmap // 8
            tile_sub_y = y_in_bgmap % 8

            for tile_x in range(0, 20):
                tile_id = self.cpu.ram.get(tile_map + tile_y * 32 + tile_x)
                if tile_offset and tile_id < 0x80:
                    tile_id += 0x100

                xy = make_SDL_Point(
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
            n: cython.int
            for n in range(0, 40):
                sprite: Sprite = Sprite.create(
                    y=self.cpu.ram.get(Mem.OAM_BASE + 4 * n + 0),
                    x=self.cpu.ram.get(Mem.OAM_BASE + 4 * n + 1),
                    tile_id=self.cpu.ram.get(Mem.OAM_BASE + 4 * n + 2),
                    flags=self.cpu.ram.get(Mem.OAM_BASE + 4 * n + 3),
                )

                if sprite.is_live():
                    if cython.compiled:
                        palette = (
                            cython.cast(
                                cython.pointer(cython.pointer(sdl2.SDL_Color)),
                                self.obp1,
                            )
                            if sprite.palette()
                            else cython.cast(
                                cython.pointer(cython.pointer(sdl2.SDL_Color)),
                                self.obp0,
                            )
                        )
                    else:
                        palette = self.obp1 if sprite.palette else self.obp0
                    # printf("Drawing sprite %d (from %04X) at %d,%d\n", tile_id, OAM_BASE + (sprite_id * 4) + 0, x, y)
                    xy = make_SDL_Point(
                        x=sprite.x - 8,
                        y=sprite.y - 16,
                    )

                    self.paint_tile(
                        sprite.tile_id,
                        xy,
                        cython.cast(cython.pointer(sdl2.SDL_Color), palette),
                        sprite.x_flip(),
                        sprite.y_flip(),
                    )

                    if dbl:
                        xy.y = sprite.y - 8
                        self.paint_tile(
                            sprite.tile_id + 1,
                            xy,
                            cython.cast(cython.pointer(sdl2.SDL_Color), palette),
                            sprite.x_flip(),
                            sprite.y_flip(),
                        )

    def paint_tile(
        self,
        tile_id: cython.int,
        offset: sdl2.SDL_Point,
        palette: cython.array(sdl2.SDL_Color, 4),
        flip_x: bool,
        flip_y: bool,
    ) -> None:
        for y in range(0, 8):
            self.paint_tile_line(tile_id, offset, palette, flip_x, flip_y, y)

        if self.debug:
            rect = make_SDL_Rect(
                x=offset.x,
                y=offset.y,
                w=8,
                h=8,
            )

            c = gen_hue(tile_id)
            sdl2.SDL_SetRenderDrawColor(self.renderer, c.r, c.g, c.b, c.a)
            sdl2.SDL_RenderDrawRect(self.renderer, rect)

            if cython.compiled:
                PyMem_Free(rect)

    def paint_tile_line(
        self,
        tile_id: cython.int,
        offset: sdl2.SDL_Point,
        palette: cython.array(sdl2.SDL_Color, 4),
        flip_x: bool,
        flip_y: bool,
        y: cython.int,
    ) -> None:
        addr: cython.int = Mem.TILE_DATA + tile_id * 16 + y * 2
        low_byte: cython.int = self.cpu.ram.get(addr)
        high_byte: cython.int = self.cpu.ram.get(addr + 1)
        x: cython.int
        for x in range(0, 8):
            low_bit: cython.int = (low_byte >> (7 - x)) & 0x01
            high_bit: cython.int = (high_byte >> (7 - x)) & 0x01
            px: cython.int = (high_bit << 1) | low_bit
            # pallette #0 = transparent, so don't draw anything
            if px > 0:
                xy = make_SDL_Point(
                    x=offset.x + (7 - x if flip_x else x),
                    y=offset.y + (7 - y if flip_y else y),
                )

                c = palette[px]
                sdl2.SDL_SetRenderDrawColor(self.renderer, c.r, c.g, c.b, c.a)
                sdl2.SDL_RenderDrawPoint(self.renderer, xy.x, xy.y)


def gen_hue(n: cython.int) -> sdl2.SDL_Color:
    region: cython.int = n // 43
    remainder: cython.int = (n - (region * 43)) * 6

    q: cython.int = 255 - remainder
    t: cython.int = remainder

    if region == 0:
        return sdl2.SDL_Color(r=255, g=t, b=0, a=0xFF)
    if region == 1:
        return sdl2.SDL_Color(r=q, g=255, b=0, a=0xFF)
    if region == 2:
        return sdl2.SDL_Color(r=0, g=255, b=t, a=0xFF)
    if region == 3:
        return sdl2.SDL_Color(r=0, g=q, b=255, a=0xFF)
    if region == 4:
        return sdl2.SDL_Color(r=t, g=0, b=255, a=0xFF)
    return sdl2.SDL_Color(r=255, g=0, b=q, a=0xFF)
