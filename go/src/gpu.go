package main

import (
	"fmt"
	"github.com/veandco/go-sdl2/sdl"
)

const (
	LCDC_ENABLED        = 1 << 7
	LCDC_WINDOW_MAP     = 1 << 6
	LCDC_WINDOW_ENABLED = 1 << 5
	LCDC_DATA_SRC       = 1 << 4
	LCDC_BG_MAP         = 1 << 3
	LCDC_OBJ_SIZE       = 1 << 2
	LCDC_OBJ_ENABLED    = 1 << 1
	LCDC_BG_WIN_ENABLED = 1 << 0
)

const (
	STAT_LYC_INTERRUPT    uint8 = 1 << 6
	STAT_OAM_INTERRUPT    uint8 = 1 << 5
	STAT_VBLANK_INTERRUPT uint8 = 1 << 4
	STAT_HBLANK_INTERRUPT uint8 = 1 << 3
	STAT_LCY_EQUAL        uint8 = 1 << 2
	STAT_MODE_BITS        uint8 = 1<<1 | 1<<0

	STAT_HBLANK  = 0x00
	STAT_VBLANK  = 0x01
	STAT_OAM     = 0x02
	STAT_DRAWING = 0x03
)

const SCALE = 2
const rmask = 0x000000ff
const gmask = 0x0000ff00
const bmask = 0x00ff0000
const amask = 0xff000000

type GPU struct {
	debug    bool
	cpu      *CPU
	headless bool
	cycle    int

	hw_window       *sdl.Window
	hw_buffer       *sdl.Texture
	hw_renderer     *sdl.Renderer
	buffer          *sdl.Surface
	renderer        *sdl.Renderer
	colors          []sdl.Color
	bgp, obp0, obp1 []sdl.Color
}

func NewGPU(cpu *CPU, title string, debug bool, headless bool) (*GPU, error) {
	var w int32 = 160
	var h int32 = 144
	if debug {
		w = 160 + 256
		h = 144
	}

	var hw_window *sdl.Window
	var hw_renderer *sdl.Renderer
	var hw_buffer *sdl.Texture
	if !headless {
		var err error
		if err = sdl.Init(uint32(sdl.INIT_VIDEO)); err != nil {
			return nil, err
		}

		hw_window, err = sdl.CreateWindow(
			fmt.Sprintf("RosettaBoy - %s", title),
			sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
			w*SCALE, h*SCALE, sdl.WINDOW_ALLOW_HIGHDPI|sdl.WINDOW_RESIZABLE,
		)
		if err != nil {
			return nil, err
		}
		hw_renderer, err = sdl.CreateRenderer(hw_window, -1, 0)
		if err != nil {
			return nil, err
		}
		sdl.SetHint(sdl.HINT_RENDER_SCALE_QUALITY, "nearest") // vs "linear"
		hw_renderer.SetLogicalSize(w, h)
		hw_renderer.CreateTexture(
			sdl.PIXELFORMAT_ABGR8888,
			sdl.TEXTUREACCESS_STREAMING,
			w, h)
	}

	buffer, err := sdl.CreateRGBSurface(0, w, h, 32, rmask, gmask, bmask, amask)
	if err != nil {
		return nil, err
	}

	renderer, err := sdl.CreateSoftwareRenderer(buffer)
	if err != nil {
		return nil, err
	}

	colors := []sdl.Color{
		{R: 0x9B, G: 0xBC, B: 0x0F, A: 0xFF},
		{R: 0x8B, G: 0xAC, B: 0x0F, A: 0xFF},
		{R: 0x30, G: 0x62, B: 0x30, A: 0xFF},
		{R: 0x0F, G: 0x38, B: 0x0F, A: 0xFF},
	}
	bgp := make([]sdl.Color, 4)
	obp0 := make([]sdl.Color, 4)
	obp1 := make([]sdl.Color, 4)

	return &GPU{
		debug, cpu, headless, 0,
		hw_window, hw_buffer, hw_renderer, buffer, renderer,
		colors, bgp, obp0, obp1,
	}, nil
}

func (self *GPU) Destroy() {
	self.hw_window.Destroy()
	self.renderer.Destroy()
}

func (self *GPU) tick() bool {
	self.cycle += 1

	// CPU STOP stops all LCD activity until a button is pressed
	if self.cpu.stop {
		return true
	}

	// Check if LCD enabled at all
	var lcdc = self.cpu.ram.get(IO_LCDC)
	if ^lcdc&LCDC_ENABLED > 0 {
		// When LCD is re-enabled, LY is 0
		// Does it become 0 as soon as disabled??
		self.cpu.ram.set(IO_LY, 0)
		if !self.debug {
			return true
		}
	}

	var lx = self.cycle % 114
	var ly = (self.cycle / 114) % 154
	self.cpu.ram.set(IO_LY, uint8(ly))

	var stat = self.cpu.ram.get(IO_STAT)

	// LYC compare & interrupt
	if self.cpu.ram.get(IO_LY) == self.cpu.ram.get(IO_LCY) {
		if stat&STAT_LYC_INTERRUPT > 0 {
			self.cpu.interrupt(INT_STAT)
		}
		self.cpu.ram._or(IO_STAT, STAT_LCY_EQUAL)
	} else {
		self.cpu.ram._and(IO_STAT, ^STAT_LCY_EQUAL)
	}

	// Set `ram[STAT].bit{0,1}` to `OAM / Drawing / HBlank / VBlank`
	if lx == 0 && ly < 144 {
		self.cpu.ram.set(IO_STAT, ((stat & ^STAT_MODE_BITS) | STAT_OAM))
		if stat&(STAT_OAM_INTERRUPT) > 0 {
			self.cpu.interrupt(INT_STAT)
		}
	} else if lx == 20 && ly < 144 {
		self.cpu.ram.set(
			IO_STAT,
			((stat & ^STAT_MODE_BITS) | STAT_DRAWING),
		)
		if ly == 0 {
			// TODO: how often should we update palettes?
			// Should every pixel reference them directly?
			self.update_palettes()
			// TODO: do we need to clear if we write every pixel?
			self.renderer.SetDrawColor(self.bgp[0].R, self.bgp[0].G, self.bgp[0].B, self.bgp[0].A)
			self.renderer.Clear()
		}
		self.draw_line(int32(ly))
		if ly == 143 {
			if self.debug {
				self.draw_debug()
			}
			if self.hw_window != nil {
				var w int32 = 160
				if self.debug {
					w = 160 + 256
				}
				self.hw_buffer.Update(nil, self.buffer.Pixels(), int(w))
				self.hw_renderer.Clear()
				self.hw_renderer.Copy(self.hw_buffer, nil, nil)
				self.hw_renderer.Present()
			}
		}
	} else if lx == 63 && ly < 144 {
		self.cpu.ram.set(IO_STAT, ((stat & ^STAT_MODE_BITS) | STAT_HBLANK))
		if stat&STAT_HBLANK_INTERRUPT > 0 {
			self.cpu.interrupt(INT_STAT)
		}
	} else if lx == 0 && ly == 144 {
		self.cpu.ram.set(IO_STAT, ((stat & ^STAT_MODE_BITS) | STAT_VBLANK))
		if stat&STAT_VBLANK_INTERRUPT > 0 {
			self.cpu.interrupt(INT_STAT)
		}
		self.cpu.interrupt(INT_VBLANK)
	}

	return true
}

func (self *GPU) update_palettes()   {}
func (self *GPU) draw_debug() bool   { return true }
func (self *GPU) draw_line(ly int32) {}
func (self *GPU) paint_tile(
	tile_id int16,
	offset *sdl.Point,
	palette *sdl.Color,
	flip_x bool,
	flip_y bool) {
}
func (self *GPU) paint_tile_line(
	tile_id int16,
	offset *sdl.Point,
	palette *sdl.Color,
	flip_x bool,
	flip_y bool,
	y int32) {
}
