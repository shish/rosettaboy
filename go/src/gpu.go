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

type Sprite struct {
	y       uint8
	x       uint8
	tile_id uint8
	flags   uint8
}

const (
	SPRITE_PALETTE = 1 << 4
	SPRITE_FLIP_X  = 1 << 5
	SPRITE_FLIP_Y  = 1 << 6
	SPRITE_BEHIND  = 1 << 7
)

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

	// FIXME: draw to buffer then blit to screen doesn't work??
	// Drawing directly to screen works though
	if !headless {
		renderer = hw_renderer
	}
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
			if self.hw_renderer != nil {
				// FIXME: drawing to a buffer then blit to screen doesn't work??
				//self.hw_buffer.Update(nil, self.buffer.Pixels(), int(self.buffer.Pitch))
				//self.hw_renderer.Clear()
				//self.hw_renderer.Copy(self.hw_buffer, nil, nil)
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

func (self *GPU) update_palettes() {
	var raw_bgp = self.cpu.ram.get(IO_BGP)
	self.bgp[0] = self.colors[(raw_bgp>>0)&0x3]
	self.bgp[1] = self.colors[(raw_bgp>>2)&0x3]
	self.bgp[2] = self.colors[(raw_bgp>>4)&0x3]
	self.bgp[3] = self.colors[(raw_bgp>>6)&0x3]

	var raw_obp0 = self.cpu.ram.get(IO_OBP0)
	self.obp0[0] = self.colors[(raw_obp0>>0)&0x3]
	self.obp0[1] = self.colors[(raw_obp0>>2)&0x3]
	self.obp0[2] = self.colors[(raw_obp0>>4)&0x3]
	self.obp0[3] = self.colors[(raw_obp0>>6)&0x3]

	var raw_obp1 = self.cpu.ram.get(IO_OBP1)
	self.obp1[0] = self.colors[(raw_obp1>>0)&0x3]
	self.obp1[1] = self.colors[(raw_obp1>>2)&0x3]
	self.obp1[2] = self.colors[(raw_obp1>>4)&0x3]
	self.obp1[3] = self.colors[(raw_obp1>>6)&0x3]
}

func (self *GPU) draw_debug() {
	var LCDC = self.cpu.ram.get(IO_LCDC)

	// Tile data
	var tile_display_width uint8 = 32
	for tile_id := 0; tile_id < 384; tile_id++ {
		var xy = sdl.Point{
			X: 160 + (int32(tile_id)%int32(tile_display_width))*8,
			Y: (int32(tile_id) / int32(tile_display_width)) * 8,
		}
		self.paint_tile(int16(tile_id), &xy, self.bgp, false, false)
	}

	// Background scroll border
	if LCDC&LCDC_BG_WIN_ENABLED != 0 {
		var rect = sdl.Rect{X: 0, Y: 0, W: 160, H: 144}
		self.renderer.SetDrawColor(255, 0, 0, 0xFF)
		self.renderer.DrawRect(&rect)
	}

	// Window tiles
	if LCDC&LCDC_WINDOW_ENABLED != 0 {
		var wnd_y = self.cpu.ram.get(IO_WY)
		var wnd_x = self.cpu.ram.get(IO_WX)
		var rect = sdl.Rect{X: int32(wnd_x - 7), Y: int32(wnd_y), W: 160, H: 144}
		self.renderer.SetDrawColor(0, 0, 255, 0xFF)
		self.renderer.DrawRect(&rect)
	}
}

func (self *GPU) draw_line(ly int32) {
	var lcdc = self.cpu.ram.get(IO_LCDC)

	// Background tiles
	if lcdc&LCDC_BG_WIN_ENABLED != 0 {
		var scroll_y = int(self.cpu.ram.get(IO_SCY))
		var scroll_x = int(self.cpu.ram.get(IO_SCX))
		var tile_offset = (lcdc & LCDC_DATA_SRC) == 0
		var background_map = _tern((lcdc&LCDC_BG_MAP) != 0, MAP_1, MAP_0)

		if self.debug {
			var xy = sdl.Point{X: 256 - int32(scroll_x), Y: ly}
			self.renderer.SetDrawColor(255, 0, 0, 0xFF)
			self.renderer.DrawPoint(xy.X, xy.Y)
		}

		var y_in_bgmap = (int(ly) - int(scroll_y)) & 0xFF // % 256
		var tile_y = y_in_bgmap / 8
		var tile_sub_y = y_in_bgmap % 8

		for tile_x := scroll_x / 8; tile_x < scroll_x/8+21; tile_x++ {
			var tile_id int16 = int16(self.cpu.ram.get(uint16(background_map + int32(tile_y%32)*32 + int32(tile_x%32))))
			if tile_offset && tile_id < 0x80 {
				tile_id += 0x100
			}
			var xy = sdl.Point{
				X: int32((tile_x*8-scroll_x)+8)%256 - 8,
				Y: int32((tile_y*8-scroll_y)+8)%256 - 8,
			}
			self.paint_tile_line(tile_id, &xy, self.bgp, false, false, tile_sub_y)
		}
	}

	// Window tiles
	if lcdc&LCDC_WINDOW_ENABLED != 0 {
		var wnd_y = self.cpu.ram.get(IO_WY)
		var wnd_x = self.cpu.ram.get(IO_WX)
		var tile_offset = (lcdc & LCDC_DATA_SRC) == 0
		var window_map = _tern((lcdc&LCDC_WINDOW_MAP) != 0, MAP_1, MAP_0)

		// blank out the background
		var rect = sdl.Rect{
			X: int32(wnd_x) - 7,
			Y: int32(wnd_y),
			W: 160,
			H: 144,
		}
		var c = self.bgp[0]
		self.renderer.SetDrawColor(c.R, c.G, c.B, c.A)
		self.renderer.FillRect(&rect)

		var y_in_bgmap = ly - int32(wnd_y)
		var tile_y = y_in_bgmap / 8
		var tile_sub_y = y_in_bgmap % 8

		for tile_x := 0; tile_x < 20; tile_x++ {
			var tile_id = int16(self.cpu.ram.get(uint16(window_map) + uint16(tile_y)*32 + uint16(tile_x)))
			if tile_offset && tile_id < 0x80 {
				tile_id += 0x100
			}
			var xy = sdl.Point{
				X: int32(tile_x*8 + int(wnd_x) - 7),
				Y: int32(tile_y*8 + int32(wnd_y)),
			}
			self.paint_tile_line(tile_id, &xy, self.bgp, false, false, int(tile_sub_y))
		}
	}

	// Sprites
	if lcdc&LCDC_OBJ_ENABLED != 0 {
		var dbl = lcdc & LCDC_OBJ_SIZE

		// TODO: sorted by x
		for n := 0; n < 40; n++ {
			var sprite = Sprite{
				y:       self.cpu.ram.get(uint16(OAM_BASE + 4*n + 0)),
				x:       self.cpu.ram.get(uint16(OAM_BASE + 4*n + 1)),
				tile_id: self.cpu.ram.get(uint16(OAM_BASE + 4*n + 2)),
				flags:   self.cpu.ram.get(uint16(OAM_BASE + 4*n + 3)),
			}

			if sprite.is_live() {
				var palette []sdl.Color
				if sprite.flags&SPRITE_PALETTE != 0 {
					palette = self.obp1
				} else {
					palette = self.obp0
				}
				//printf("Drawing sprite %d (from %04X) at %d,%d\n", tile_id, OAM_BASE + (sprite_id * 4) + 0, x, y);
				var xy = sdl.Point{
					X: int32(sprite.x) - 8,
					Y: int32(sprite.y) - 16,
				}
				self.paint_tile(
					int16(sprite.tile_id),
					&xy,
					palette,
					sprite.flags&SPRITE_FLIP_X != 0,
					sprite.flags&SPRITE_FLIP_Y != 0,
				)

				if dbl != 0 {
					xy.Y = int32(sprite.y) - 8
					self.paint_tile(
						int16(sprite.tile_id+1),
						&xy,
						palette,
						sprite.flags&SPRITE_FLIP_X != 0,
						sprite.flags&SPRITE_FLIP_Y != 0,
					)
				}
			}
		}
	}
}

func (self *GPU) paint_tile(
	tile_id int16,
	offset *sdl.Point,
	palette []sdl.Color,
	flip_x bool,
	flip_y bool) {
	for y := 0; y < 8; y++ {
		self.paint_tile_line(tile_id, offset, palette, flip_x, flip_y, y)
	}

	if self.debug {
		var rect = sdl.Rect{
			X: offset.X,
			Y: offset.Y,
			W: 8,
			H: 8,
		}
		var c = gen_hue(uint8(tile_id))
		self.renderer.SetDrawColor(c.R, c.G, c.B, c.A)
		self.renderer.DrawRect(&rect)
	}
}

func _tern(v bool, a, b int) int32 {
	if v {
		return int32(a)
	} else {
		return int32(b)
	}
}

func (self *GPU) paint_tile_line(
	tile_id int16,
	offset *sdl.Point,
	palette []sdl.Color,
	flip_x bool,
	flip_y bool,
	y int) {
	var addr uint16 = uint16(int(TILE_DATA_TABLE_1) + int(tile_id)*16 + y*2)
	var low_byte uint8 = self.cpu.ram.get(addr)
	var high_byte uint8 = self.cpu.ram.get(addr + 1)
	for x := 0; x < 8; x++ {
		var low_bit uint8 = (low_byte >> (7 - x)) & 0x01
		var high_bit uint8 = (high_byte >> (7 - x)) & 0x01
		var px uint8 = (high_bit << 1) | low_bit
		// pallette #0 = transparent, so don't draw anything
		if px > 0 {
			var xy = sdl.Point{
				X: int32(offset.X + _tern(flip_x, 7-x, x)),
				Y: int32(offset.Y + _tern(flip_y, 7-y, y)),
			}
			if offset.X <= 160 && xy.X >= 160 {
				return
			}
			var c = palette[px]
			self.renderer.SetDrawColor(c.R, c.G, c.B, c.A)
			self.renderer.DrawPoint(xy.X, xy.Y)
		}
	}
}

func gen_hue(n uint8) sdl.Color {
	var region = n / 43
	var remainder = (n - (region * 43)) * 6

	var q = 255 - remainder
	var t = remainder

	switch region {
	case 0:
		return sdl.Color{R: 255, G: t, B: 0, A: 0xFF}
	case 1:
		return sdl.Color{R: q, G: 255, B: 0, A: 0xFF}
	case 2:
		return sdl.Color{R: 0, G: 255, B: t, A: 0xFF}
	case 3:
		return sdl.Color{R: 0, G: q, B: 255, A: 0xFF}
	case 4:
		return sdl.Color{R: t, G: 0, B: 255, A: 0xFF}
	default:
		return sdl.Color{R: 255, G: 0, B: q, A: 0xFF}
	}
}

func (self *Sprite) is_live() bool {
	return self.x > 0 && self.x < 168 && self.y > 0 && self.y < 160
}
