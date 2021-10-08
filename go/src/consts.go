package main

const (
	VRAM_BASE         = 0x8000
	TILE_DATA_TABLE_0 = 0x8800
	TILE_DATA_TABLE_1 = 0x8000
	BACKGROUND_MAP_0  = 0x9800
	BACKGROUND_MAP_1  = 0x9C00
	WINDOW_MAP_0      = 0x9800
	WINDOW_MAP_1      = 0x9C00
	OAM_BASE          = 0xFE00
)

const (
	IO_JOYP = 0xFF00

	IO_SB = 0xFF01 // Serial Data
	IO_SC = 0xFF02 // Serial Control

	IO_DIV  = 0xFF04
	IO_TIMA = 0xFF05
	IO_TMA  = 0xFF06
	IO_TAC  = 0xFF07

	IO_IF = 0xFF0F

	IO_NR10 = 0xFF10
	IO_NR11 = 0xFF11
	IO_NR12 = 0xFF12
	IO_NR13 = 0xFF13
	IO_NR14 = 0xFF14

	IO_NR20 = 0xFF15
	IO_NR21 = 0xFF16
	IO_NR22 = 0xFF17
	IO_NR23 = 0xFF18
	IO_NR24 = 0xFF19

	IO_NR30 = 0xFF1A
	IO_NR31 = 0xFF1B
	IO_NR32 = 0xFF1C
	IO_NR33 = 0xFF1D
	IO_NR34 = 0xFF1E

	IO_NR40 = 0xFF1F
	IO_NR41 = 0xFF20
	IO_NR42 = 0xFF21
	IO_NR43 = 0xFF22
	IO_NR44 = 0xFF23

	IO_NR50 = 0xFF24
	IO_NR51 = 0xFF25
	IO_NR52 = 0xFF26

	IO_LCDC = 0xFF40
	IO_STAT = 0xFF41
	IO_SCY  = 0xFF42 // SCROLL_Y
	IO_SCX  = 0xFF43 // SCROLL_X
	IO_LY   = 0xFF44 // LY aka currently drawn line 0-153 >144 = vblank
	IO_LCY  = 0xFF45
	IO_DMA  = 0xFF46
	IO_BGP  = 0xFF47
	IO_OBP0 = 0xFF48
	IO_OBP1 = 0xFF49
	IO_WY   = 0xFF4A
	IO_WX   = 0xFF4B

	IO_BOOT = 0xFF50

	IO_IE = 0xFFFF
)

const (
	LCDC_ENABLED        = 0b10000000
	LCDC_WINDOW_MAP     = 0b01000000
	LCDC_WINDOW_ENABLED = 0b00100000
	LCDC_DATA_SRC       = 0b00010000
	LCDC_BG_MAP         = 0b00001000
	LCDC_OBJ_SIZE       = 0b00000100
	LCDC_OBJ_ENABLED    = 0b00000010
	LCDC_BG_WIN_ENABLED = 0b00000001
)

// STATFlag
const (
	LYC_INTERRUPT    = 1 << 6
	OAM_INTERRUPT    = 1 << 5
	VBLANK_INTERRUPT = 1 << 4
	HBLANK_INTERRUPT = 1 << 3
	LCY_EQUAL        = 1 << 2
	MODE             = 1<<1 | 1<<0
)

// STATMode
const (
	HBLANK  = 0x00
	VBLANK  = 0x01
	OAM     = 0x02
	DRAWING = 0x03
)

// Interrupt
const (
	VBLANK           = 1 << 0
	STAT             = 1 << 1
	TIMER            = 1 << 2
	SERIAL           = 1 << 3
	INTERRUPT_JOYPAD = 1 << 4
)

// Joypad
const (
	JOYPAD_MODE_BUTTONS = 1 << 5
	JOYPAD_MODE_DPAD    = 1 << 4
	JOYPAD_DOWN         = 1 << 3
	JOYPAD_START        = 1 << 3
	JOYPAD_UP           = 1 << 2
	JOYPAD_SELECT       = 1 << 2
	JOYPAD_LEFT         = 1 << 1
	JOYPAD_B            = 1 << 1
	JOYPAD_RIGHT        = 1 << 0
	JOYPAD_A            = 1 << 0
)

// InterruptHandler
const (
	VBLANK_HANDLER = 0x40
	LCD_HANDLER    = 0x48
	TIMER_HANDLER  = 0x50
	SERIAL_HANDLER = 0x58
	JOYPAD_HANDLER = 0x60
)
