import std/bitops

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
        #[
        hw_renderer: Option<sdl2::render::Canvas<sdl2::video::Window>>,
        hw_buffer: Option<sdl2::render::Texture>,
        renderer: sdl2::render::Canvas<sdl2::surface::Surface<'a>>,
        colors: [Color; 4],
        bgp: [Color; 4],
        obp0: [Color; 4],
        obp1: [Color; 4],
        ]#

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


proc create*(cpu: cpu.CPU, ram: ram.RAM, cart_name: string, headless: bool, debug: bool): GPU =
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

    return GPU(
        cpu: cpu,
        ram: ram,
        cart_name: cart_name,
        headless: headless,
        debug: debug,
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
    # echo self.cycle, " ", ly, " ", lx
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
        self.ram.set(consts.Mem_STAT, bitor(bitand(self.ram.get(consts.Mem_STAT), bitnot(Stat_MODE_BITS)), Stat_DRAWING));
#        if(ly == 0):
#            # TODO: how often should we update palettes?
#            # Should every pixel reference them directly?
#            self.update_palettes();
#            auto c = self.bgp[0];
#            SDL_SetRenderDrawColor(self.renderer, c.r, c.g, c.b, c.a);
#            SDL_RenderClear(self.renderer);
#        self.draw_line(ly);
#        if(ly == 143):
#            if(self.debug):
#                self.draw_debug()
#            if(self.hw_renderer):
#                SDL_UpdateTexture(self.hw_buffer, NULL, self.buffer.pixels, self.buffer.pitch);
#                SDL_RenderClear(self.hw_renderer);
#                SDL_RenderCopy(self.hw_renderer, self.hw_buffer, NULL, NULL);
#                SDL_RenderPresent(self.hw_renderer);
    elif(lx == 63 and ly < 144):
        self.ram.set(consts.Mem_STAT, bitor(bitand(self.ram.get(consts.Mem_STAT), bitnot(Stat_MODE_BITS)), Stat_HBLANK));
        if bitand(self.ram.get(consts.Mem_STAT), Stat_HBLANK_INTERRUPT) > 0:
            self.cpu.interrupt(consts.Interrupt_STAT);
    elif(lx == 0 and ly == 144):
        self.ram.set(consts.Mem_STAT, bitor(bitand(self.ram.get(consts.Mem_STAT), bitnot(Stat_MODE_BITS)), Stat_VBLANK));
        if bitand(self.ram.get(consts.Mem_STAT), Stat_VBLANK_INTERRUPT) > 0:
            self.cpu.interrupt(consts.Interrupt_STAT);
        self.cpu.interrupt(consts.Interrupt_VBLANK);
