package main

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

// STAT
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

type GPU struct {
	debug    bool
	cpu      CPU
	headless bool
}

func NewGPU(cpu CPU, debug bool, headless bool) GPU {
	return GPU{debug, cpu, headless}
}

func (self GPU) tick() bool {
	return true
}
