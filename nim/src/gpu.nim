import std/bitops
import std/strformat

import sdl2

import consts
import cpu
import ram

type
    GPU* = object
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

const SCALE = 2
const rmask: uint32 = 0x000000ff
const gmask: uint32 = 0x0000ff00
const bmask: uint32 = 0x00ff0000
const amask: uint32 = 0xff000000.uint32

proc create*(cpu: cpu.CPU, ram: ram.RAM, cart_name: string, headless: bool, debug: bool): GPU =
#[
    if not headless:
        discard sdl2.init(INIT_EVERYTHING)
        var
            window: WindowPtr
            render: RendererPtr

        window = createWindow("SDL Skeleton", 100, 100, 640, 480, SDL_WINDOW_SHOWN)
        render = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)

        var
            evt = sdl2.defaultEvent
            runGame = true

        while runGame:
            while pollEvent(evt):
                if evt.kind == QuitEvent:
                    runGame = false
                    break

            render.setDrawColor 0, 0, 0, 255
            render.clear
            render.present

        destroy render
        destroy window
]#

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

# FIXME: implement self
proc tick*(self: var GPU) =
    self.cycle += 1

    # CPU STOP stops all LCD activity until a button is pressed
    if self.cpu.stop:
        return

    # Check if LCD enabled at all
    let lcdc = self.ram.get(consts.Mem_LCDC)
    if bitnot(bitand(lcdc, LCDC_ENABLED)) > 0:
        # When LCD is re-enabled, LY is 0
        # Does it become 0 as soon as disabled??
        self.ram.set(consts.Mem_LY, 0);
        if not self.debug:
            return

    let lx = (self.cycle mod 114).uint8;
    let ly = ((self.cycle div 114) mod 154).uint8;
    self.ram.set(consts.Mem_LY, ly);

    # LYC compare & interrupt
    if(self.ram.get(consts.Mem_LY) == self.ram.get(consts.Mem_LYC)):
        if bitand(self.ram.get(consts.Mem_STAT), Stat_LYC_INTERRUPT) > 0:
            self.cpu.interrupt(consts.Interrupt_STAT);
        self.ram.mem_or(consts.Mem_STAT, Stat_LYC_EQUAL);
    else:
        self.ram.mem_and(consts.Mem_STAT, bitnot(Stat_LYC_EQUAL));

    # Set mode
    if(lx == 0 and ly < 144):
        self.ram.set(consts.Mem_STAT, bitor(bitand(self.ram.get(consts.Mem_STAT), bitnot(Stat_MODE_BITS)), Stat_OAM));
        if bitand(self.ram.get(consts.Mem_STAT), Stat_OAM_INTERRUPT) > 0:
            self.cpu.interrupt(consts.Interrupt_STAT);
    elif(lx == 20 and ly < 144):
        self.ram.set(consts.Mem_STAT, bitor(bitand(self.ram.get(consts.Mem_STAT), bitnot(Stat_MODE_BITS)),
                Stat_DRAWING));
        if(ly == 0):
            # TODO: how often should we update palettes?
            # Should every pixel reference them directly?
            # FIXME: self.update_palettes();
            var c = self.bgp[0];
            self.renderer.setDrawColor(c.r, c.g, c.b, c.a);
            self.renderer.clear()
        # FIXME: self.draw_line(ly);
        if(ly == 143):
            # FIXME: if(self.debug):
            # FIXME:     self.draw_debug()
            if self.hw_renderer != nil:
                self.hw_buffer.updateTexture(nil, self.buffer.pixels, self.buffer.pitch);
                self.hw_renderer.clear()
                self.renderer.copy(self.hw_buffer, nil, nil)
                self.hw_renderer.present()
    elif(lx == 63 and ly < 144):
        self.ram.set(consts.Mem_STAT, bitor(bitand(self.ram.get(consts.Mem_STAT), bitnot(Stat_MODE_BITS)),
                Stat_HBLANK));
        if bitand(self.ram.get(consts.Mem_STAT), Stat_HBLANK_INTERRUPT) > 0:
            self.cpu.interrupt(consts.Interrupt_STAT);
    elif(lx == 0 and ly == 144):
        self.ram.set(consts.Mem_STAT, bitor(bitand(self.ram.get(consts.Mem_STAT), bitnot(Stat_MODE_BITS)),
                Stat_VBLANK));
        if bitand(self.ram.get(consts.Mem_STAT), Stat_VBLANK_INTERRUPT) > 0:
            self.cpu.interrupt(consts.Interrupt_STAT);
        self.cpu.interrupt(consts.Interrupt_VBLANK);
