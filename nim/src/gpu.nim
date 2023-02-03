import std/bitops
import std/strformat

import sdl2

import consts
import cpu
import ram

type
    Sprite = object
        y: uint8
        x: uint8
        tile_id: uint8
        flags: uint8
    GPU* = ref object
        cpu: cpu.CPU
        ram: ram.RAM
        cart_name: string
        headless: bool
        debug: bool
        cycle: int
        hw_window: sdl2.WindowPtr
        hw_renderer: sdl2.RendererPtr
        hw_buffer: sdl2.TexturePtr
        renderer: sdl2.RendererPtr
        buffer: sdl2.SurfacePtr
        colors: array[4, sdl2.Color]
        bgp: array[4, sdl2.Color]
        obp0: array[4, sdl2.Color]
        obp1: array[4, sdl2.Color]


const LCDC_ENABLED*: uint8 = 1 shl 7
const LCDC_WINDOW_MAP*: uint8 = 1 shl 6
const LCDC_WINDOW_ENABLED*: uint8 = 1 shl 5
const LCDC_DATA_SRC*: uint8 = 1 shl 4
const LCDC_BG_MAP*: uint8 = 1 shl 3
const LCDC_OBJ_SIZE*: uint8 = 1 shl 2
const LCDC_OBJ_ENABLED*: uint8 = 1 shl 1
const LCDC_BG_WIN_ENABLED*: uint8 = 1 shl 0

const Stat_LYC_INTERRUPT*: uint8 = 1 shl 6
const Stat_OAM_INTERRUPT*: uint8 = 1 shl 5
const Stat_VBLANK_INTERRUPT*: uint8 = 1 shl 4
const Stat_HBLANK_INTERRUPT*: uint8 = 1 shl 3
const Stat_LYC_EQUAL*: uint8 = 1 shl 2
const Stat_MODE_BITS*: uint8 = bitor(1 shl 1, 1 shl 0)

const Stat_HBLANK*: uint8 = 0x00
const Stat_VBLANK*: uint8 = 0x01
const Stat_OAM*: uint8 = 0x02
const Stat_DRAWING*: uint8 = 0x03

const SPRITE_PALETTE: uint8 = 0x10
const SPRITE_FLIP_X: uint8 = 0x20
const SPRITE_FLIP_Y: uint8 = 0x40
const SPRITE_BEHIND: uint8 = 0x80


const SCALE = 2
const rmask: uint32 = 0x000000ff
const gmask: uint32 = 0x0000ff00
const bmask: uint32 = 0x00ff0000
const amask: uint32 = 0xff000000.uint32

proc create*(cpu: cpu.CPU, ram: ram.RAM, cart_name: string, headless: bool, debug: bool): GPU =
    var w = 160
    var h = 144
    var hw_window: sdl2.WindowPtr
    var hw_renderer: sdl2.RendererPtr
    var hw_buffer: sdl2.TexturePtr
    if debug:
        w = 160 + 256
        h = 144
    if not headless:
        discard sdl2.init(sdl2.INIT_VIDEO)
        hw_window = sdl2.createWindow(
            fmt"RosettaBoy - {cart_name}".cstring,
            SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED,
            (w * SCALE).cint,
            (h * SCALE).cint,
            bitor(SDL_WINDOW_SHOWN, SDL_WINDOW_ALLOW_HIGHDPI, SDL_WINDOW_RESIZABLE)
        )
        hw_renderer = sdl2.createRenderer(hw_window, -1, 0)
        discard sdl2.setHint(HINT_RENDER_SCALE_QUALITY, "nearest") # vs "linear"
        discard hw_renderer.setLogicalSize(w.cint, h.cint)
        hw_buffer = sdl2.createTexture(hw_renderer, SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STREAMING, w.cint, h.cint)

    var buffer = sdl2.createRGBSurface(0, w.cint, h.cint, 32, rmask, gmask, bmask, amask)
    var renderer = sdl2.createSoftwareRenderer(buffer)

    # Colors
    let colors = [
        sdl2.color(0x9B, 0xBC, 0x0F, 0xFF),
        sdl2.color(0x8B, 0xAC, 0x0F, 0xFF),
        sdl2.color(0x30, 0x62, 0x30, 0xFF),
        sdl2.color(0x0F, 0x38, 0x0F, 0xFF),
    ]

    return GPU(
        cpu: cpu,
        ram: ram,
        cart_name: cart_name,
        headless: headless,
        debug: debug,
        hw_window: hw_window,
        hw_renderer: hw_renderer,
        hw_buffer: hw_buffer,
        renderer: renderer,
        buffer: buffer,
        colors: colors,
    )

func palette(self: Sprite): bool =
    bitand(self.flags, SPRITE_PALETTE) > 0

func x_flip(self: Sprite): bool =
    bitand(self.flags, SPRITE_FLIP_X) > 0

func y_flip(self: Sprite): bool =
    bitand(self.flags, SPRITE_FLIP_Y) > 0

proc update_palettes(self: GPU) =
    let raw_bgp = self.ram.get(consts.Mem_BGP)
    self.bgp[0] = self.colors[bitand((raw_bgp shr 0), 0x3)]
    self.bgp[1] = self.colors[bitand((raw_bgp shr 2), 0x3)]
    self.bgp[2] = self.colors[bitand((raw_bgp shr 4), 0x3)]
    self.bgp[3] = self.colors[bitand((raw_bgp shr 6), 0x3)]

    let raw_obp0 = self.ram.get(consts.Mem_OBP0)
    self.obp0[0] = self.colors[bitand((raw_obp0 shr 0), 0x3)]
    self.obp0[1] = self.colors[bitand((raw_obp0 shr 2), 0x3)]
    self.obp0[2] = self.colors[bitand((raw_obp0 shr 4), 0x3)]
    self.obp0[3] = self.colors[bitand((raw_obp0 shr 6), 0x3)]

    let raw_obp1 = self.ram.get(consts.Mem_OBP1)
    self.obp1[0] = self.colors[bitand((raw_obp1 shr 0), 0x3)]
    self.obp1[1] = self.colors[bitand((raw_obp1 shr 2), 0x3)]
    self.obp1[2] = self.colors[bitand((raw_obp1 shr 4), 0x3)]
    self.obp1[3] = self.colors[bitand((raw_obp1 shr 6), 0x3)]

proc gen_hue(n: uint8): sdl2.Color =
    let region: uint8 = n div 43
    let remainder: uint8 = (n - (region * 43)) * 6

    let q: uint8 = 255 - remainder
    let t = remainder

    return case region:
        of 0: sdl2.color(255, t, 0, 0xFF)
        of 1: sdl2.color(q, 255, 0, 0xFF)
        of 2: sdl2.color(0, 255, t, 0xFF)
        of 3: sdl2.color(0, q, 255, 0xFF)
        of 4: sdl2.color(t, 0, 255, 0xFF)
        else: sdl2.color(255, 0, q, 0xFF)

proc paint_tile_line(self: GPU, tile_id: int16, offset: sdl2.Point, palette: array[4, sdl2.Color], flip_x: bool,
        flip_y: bool, y: int32) =
    let addr_x: uint16 = (consts.Mem_TILE_DATA.int + tile_id.int * 16 + y.int * 2).uint16
    let low_byte: uint8 = self.ram.get(addr_x)
    let high_byte: uint8 = self.ram.get(addr_x + 1)
    for x in 0..8:
        let low_bit = bitand((low_byte shr (7 - x)), 0x01)
        let high_bit = bitand((high_byte shr (7 - x)), 0x01)
        let px = bitor((high_bit shl 1), low_bit)
        # pallette #0 = transparent, so don't draw anything
        if(px > 0):
            let xy = sdl2.point(
                offset.x + (if flip_x: 7 - x else: x),
                offset.y + (if flip_y: 7 - y else: y),
            )
            let c = palette[px]
            self.renderer.setDrawColor(c.r, c.g, c.b, c.a)
            self.renderer.drawPoint(xy.x, xy.y)

proc paint_tile(self: GPU, tile_id: int16, offset: sdl2.Point, palette: array[4, sdl2.Color], flip_x: bool,
        flip_y: bool) =
    for y in 0..8:
        self.paint_tile_line(tile_id, offset, palette, flip_x, flip_y, y.int32)

    if(self.debug):
        var rect = sdl2.rect(
            offset.x,
            offset.y,
            8,
            8,
        )
        let c = gen_hue(tile_id.uint8) # FIXME: uint8 vs uint16??
        self.renderer.setDrawColor(c.r, c.g, c.b, c.a)
        self.renderer.drawRect(rect)

proc draw_debug(self: GPU) =
    let lcdc = self.ram.get(consts.Mem_LCDC)

    # Tile data
    let tile_display_width = 32
    for tile_id in 0..384:
        let xy = sdl2.point(
            160 + (tile_id mod tile_display_width) * 8,
            (tile_id div tile_display_width) * 8,
        )
        self.paint_tile(tile_id.int16, xy, self.bgp, false, false)

    # Background scroll border
    if bitand(lcdc, LCDC_BG_WIN_ENABLED) != 0:
        var rect = sdl2.rect(0, 0, 160, 144)
        self.renderer.setDrawColor(255, 0, 0, 0xFF)
        self.renderer.drawRect(rect)

    # Window tiles
    if bitand(lcdc, LCDC_WINDOW_ENABLED) != 0:
        let wnd_y = self.ram.get(consts.Mem_WY)
        let wnd_x = self.ram.get(consts.Mem_WX)
        var rect = sdl2.rect((wnd_x - 7).cint, wnd_y.cint, 160, 144)
        self.renderer.setDrawColor(0, 0, 255, 0xFF)
        self.renderer.drawRect(rect)

func is_live(self: Sprite): bool =
    return self.x > 0 and self.x < 168 and self.y > 0 and self.y < 160

proc draw_line(self: GPU, ly: uint32) =
    let lcdc = self.ram.get(consts.Mem_LCDC)

    # Background tiles
    if bitand(lcdc, LCDC_BG_WIN_ENABLED) != 0:
        let scroll_y = self.ram.get(consts.Mem_SCY)
        let scroll_x = self.ram.get(consts.Mem_SCX)
        let tile_offset = bitand(lcdc, LCDC_DATA_SRC) == 0
        let tile_map = if bitand(lcdc, LCDC_BG_MAP) != 0: consts.Mem_MAP_1 else: consts.Mem_MAP_0

        if self.debug:
            let xy = sdl2.point(256 - scroll_x, ly)
            self.renderer.setDrawColor(255, 0, 0, 0xFF)
            self.renderer.drawPoint(xy.x, xy.y)

        let y_in_bgmap = (ly + scroll_y) mod 256
        let tile_y = y_in_bgmap div 8
        let tile_sub_y = y_in_bgmap mod 8

        for lx in countup(0, 160, 8):
            let x_in_bgmap = (lx.uint8 + scroll_x) mod 256
            let tile_x = x_in_bgmap div 8
            let tile_sub_x = x_in_bgmap mod 8

            var tile_id: int16 = self.ram.get((tile_map + tile_y * 32 + tile_x).uint16).int16
            if(tile_offset and tile_id < 0x80):
                tile_id += 0x100
            let xy = sdl2.point(
                (lx.int - tile_sub_x.int).cint,
                (ly.int - tile_sub_y.int).cint,
            )
            self.paint_tile_line(tile_id, xy, self.bgp, false, false, tile_sub_y.int32)

    # Window tiles
    if bitand(lcdc, LCDC_WINDOW_ENABLED) != 0:
        let wnd_y = self.ram.get(consts.Mem_WY)
        let wnd_x = self.ram.get(consts.Mem_WX)
        let tile_offset = bitnot(bitand(lcdc, LCDC_DATA_SRC)) != 0
        let tile_map = if bitand(lcdc, LCDC_WINDOW_MAP) != 0: consts.Mem_MAP_1 else: consts.Mem_MAP_0

        # blank out the background
        var rect = sdl2.rect(
            (wnd_x - 7).cint,
            (wnd_y).cint,
            160.cint,
            144.cint,
        )
        let c = self.bgp[0]
        self.renderer.setDrawColor(c.r, c.g, c.b, c.a)
        self.renderer.fillRect(rect)

        let y_in_bgmap = ly - wnd_y
        let tile_y = y_in_bgmap div 8
        let tile_sub_y = y_in_bgmap mod 8

        for tile_x in 0..20:
            var tile_id: int16 = self.ram.get((tile_map + tile_y * 32 + tile_x.uint32).uint16).int16
            if(tile_offset and tile_id < 0x80):
                tile_id += 0x100
            let xy = sdl2.point(
                (tile_x.uint8 * 8 + wnd_x - 7).cint,
                (tile_y * 8 + wnd_y).cint,
            )
            self.paint_tile_line(tile_id, xy, self.bgp, false, false, tile_sub_y.int32)

    # Sprites
    if bitand(lcdc, LCDC_OBJ_ENABLED) != 0:
        let dbl = bitand(lcdc, LCDC_OBJ_SIZE) != 0

        # TODO: sorted by x
        # let sprites: [Sprite; 40] = []
        # memcpy(sprites, &ram.data[OAM_BASE], 40 * sizeof(Sprite))
        # for sprite in sprites.iter() {
        for n in 0..40:
            let sprite = Sprite(
                y: self.ram.get(consts.Mem_OAM_BASE + 4 * n.uint16 + 0),
                x: self.ram.get(consts.Mem_OAM_BASE + 4 * n.uint16 + 1),
                tile_id: self.ram.get(consts.Mem_OAM_BASE + 4 * n.uint16 + 2),
                flags: self.ram.get(consts.Mem_OAM_BASE + 4 * n.uint16 + 3),
            )

            if sprite.is_live():
                let palette = if sprite.palette(): self.obp1 else: self.obp0
                # printf("Drawing sprite %d (from %04X) at %d,%d\n", tile_id, OAM_BASE + (sprite_id * 4) + 0, x, y)
                var xy = sdl2.point(
                    (sprite.x - 8).cint,
                    (sprite.y - 16).cint,
                )
                self.paint_tile(sprite.tile_id.int16, xy, palette, sprite.x_flip(), sprite.y_flip())

                if(dbl):
                    xy.y = (sprite.y - 8).cint
                    self.paint_tile(sprite.tile_id.int16 + 1, xy, palette, sprite.x_flip(), sprite.y_flip())

proc tick*(self: GPU) =
    self.cycle += 1

    # CPU STOP stops all LCD activity until a button is pressed
    if self.cpu.stop:
        return

    # Check if LCD enabled at all
    let lcdc = self.ram.get(consts.Mem_LCDC)
    if bitand(lcdc, LCDC_ENABLED) == 0:
        # When LCD is re-enabled, LY is 0
        # Does it become 0 as soon as disabled??
        self.ram.set(consts.Mem_LY, 0)
        if not self.debug:
            return

    let lx = (self.cycle mod 114).uint8
    let ly = ((self.cycle div 114) mod 154).uint8
    self.ram.set(consts.Mem_LY, ly)

    var stat = self.ram.get(consts.Mem_STAT)
    stat = bitand(stat, Stat_MODE_BITS)
    stat = bitand(stat, Stat_LYC_EQUAL)

    # LYC compare & interrupt
    if(ly == self.ram.get(consts.Mem_LYC)):
        stat = bitor(stat, Stat_LYC_EQUAL)
        if bitand(stat, Stat_LYC_INTERRUPT) != 0:
            self.cpu.interrupt(consts.Interrupt_STAT)

    # Set mode
    if(lx == 0 and ly < 144):
        stat = bitor(stat, Stat_OAM)
        if bitand(stat, Stat_OAM_INTERRUPT) != 0:
            self.cpu.interrupt(consts.Interrupt_STAT)
    elif(lx == 20 and ly < 144):
        stat = bitor(stat, Stat_DRAWING)
        if(ly == 0):
            # TODO: how often should we update palettes?
            # Should every pixel reference them directly?
            self.update_palettes()
            var c = self.bgp[0]
            self.renderer.setDrawColor(c.r, c.g, c.b, c.a)
            self.renderer.clear()
        self.draw_line(ly)
        if(ly == 143):
            if self.debug:
                self.draw_debug()
            if self.hw_renderer != nil:
                self.hw_buffer.updateTexture(nil, self.buffer.pixels, self.buffer.pitch)
                self.hw_renderer.copy(self.hw_buffer, nil, nil)
                self.hw_renderer.present()
    elif(lx == 63 and ly < 144):
        stat = bitor(stat, Stat_HBLANK)
        if bitand(stat, Stat_HBLANK_INTERRUPT) != 0:
            self.cpu.interrupt(consts.Interrupt_STAT)
    elif(lx == 0 and ly == 144):
        stat = bitor(stat, Stat_VBLANK)
        if bitand(stat, Stat_VBLANK_INTERRUPT) != 0:
            self.cpu.interrupt(consts.Interrupt_STAT)
        self.cpu.interrupt(consts.Interrupt_VBLANK)
    self.ram.set(consts.Mem_STAT, stat)
