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
	STAT_LYC_INTERRUPT    = 1 << 6
	STAT_OAM_INTERRUPT    = 1 << 5
	STAT_VBLANK_INTERRUPT = 1 << 4
	STAT_HBLANK_INTERRUPT = 1 << 3
	STAT_LCY_EQUAL        = 1 << 2
	STAT_MODE             = 1<<1 | 1<<0

	STAT_HBLANK  = 0x00
	STAT_VBLANK  = 0x01
	STAT_OAM     = 0x02
	STAT_DRAWING = 0x03
)

const rmask = 0x000000ff
const gmask = 0x0000ff00
const bmask = 0x00ff0000
const amask = 0xff000000

type GPU struct {
	debug    bool
	cpu      *CPU
	headless bool
	cycle    int

	window          *sdl.Window
	buffer          *sdl.Surface
	renderer        *sdl.Renderer
	colors          []sdl.Color
	bgp, obp0, obp1 []sdl.Color
}

func NewGPU(cpu *CPU, title string, debug bool, headless bool) GPU {
	var w int32 = 160
	var h int32 = 144
	if debug {
		w = 160 + 256
		h = 144
	}

	var window *sdl.Window
	if !headless {
		if err := sdl.Init(uint32(sdl.INIT_VIDEO)); err != nil {
			panic(err)
		}

		window_, err := sdl.CreateWindow(
			fmt.Sprintf("RosettaBoy - %s", title),
			sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
			w, h, sdl.WINDOW_SHOWN,
		)
		if err != nil {
			panic(err)
		}
		window = window_
	}

	buffer, err := sdl.CreateRGBSurface(0, w, h, 32, rmask, gmask, bmask, amask)
	if err != nil {
		panic(err)
	}

	renderer, err := sdl.CreateSoftwareRenderer(buffer)
	if err != nil {
		panic(err)
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

	return GPU{debug, cpu, headless, 0, window, buffer, renderer, colors, bgp, obp0, obp1}
}

func (self *GPU) Destroy() {
	self.window.Destroy()
	self.renderer.Destroy()
}

func (self *GPU) tick() bool {
	self.cycle += 1

	// TODO: this is just the minimal amount of code to get
	// something on screen
	if self.cycle%17556 == 20 {
		rect := sdl.Rect{X: 0, Y: 0, W: 200, H: 200}
		self.buffer.FillRect(&rect, 0xffff0000)

		rect = sdl.Rect{X: int32(self.cycle % 100), Y: 0, W: 200, H: 200}
		self.buffer.FillRect(&rect, 0xffffff00)

		if !self.headless {
			var window_surface, err = self.window.GetSurface()
			if err != nil {
				panic(err)
			}
			self.buffer.BlitScaled(nil, window_surface, nil)
			self.window.UpdateSurface()
		}
	}

	return true
}
