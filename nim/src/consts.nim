const MEM_VBlankHandler*: uint16 = 0x40
const MEM_LcdHandler*: uint16 = 0x48
const MEM_TimerHandler*: uint16 = 0x50
const MEM_SerialHandler*: uint16 = 0x58
const MEM_JoypadHandler*: uint16 = 0x60


const MEM_TILE_DATA*: uint16 = 0x8000
const MEM_MAP_0*: uint16 = 0x9800
const MEM_MAP_1*: uint16 = 0x9C00
const MEM_OAM_BASE*: uint16 = 0xFE00

const MEM_JOYP*: uint16 = 0xFF00

const MEM_SB*: uint16 = 0xFF01 # Serial Data
const MEM_SC*: uint16 = 0xFF02 # Serial Control

const MEM_DIV*: uint16 = 0xFF04
const MEM_TIMA*: uint16 = 0xFF05
const MEM_TMA*: uint16 = 0xFF06
const MEM_TAC*: uint16 = 0xFF07

const MEM_IF*: uint16 = 0xFF0F

const MEM_NR10*: uint16 = 0xFF10
const MEM_NR11*: uint16 = 0xFF11
const MEM_NR12*: uint16 = 0xFF12
const MEM_NR13*: uint16 = 0xFF13
const MEM_NR14*: uint16 = 0xFF14

const MEM_NR20*: uint16 = 0xFF15
const MEM_NR21*: uint16 = 0xFF16
const MEM_NR22*: uint16 = 0xFF17
const MEM_NR23*: uint16 = 0xFF18
const MEM_NR24*: uint16 = 0xFF19

const MEM_NR30*: uint16 = 0xFF1A
const MEM_NR31*: uint16 = 0xFF1B
const MEM_NR32*: uint16 = 0xFF1C
const MEM_NR33*: uint16 = 0xFF1D
const MEM_NR34*: uint16 = 0xFF1E

const MEM_NR40*: uint16 = 0xFF1F
const MEM_NR41*: uint16 = 0xFF20
const MEM_NR42*: uint16 = 0xFF21
const MEM_NR43*: uint16 = 0xFF22
const MEM_NR44*: uint16 = 0xFF23

const MEM_NR50*: uint16 = 0xFF24
const MEM_NR51*: uint16 = 0xFF25
const MEM_NR52*: uint16 = 0xFF26

const MEM_LCDC*: uint16 = 0xFF40
const MEM_STAT*: uint16 = 0xFF41
const MEM_SCY*: uint16 = 0xFF42 # SCROLL_Y
const MEM_SCX*: uint16 = 0xFF43 # SCROLL_X
const MEM_LY*: uint16 = 0xFF44 # LY aka currently drawn line, 0-153, >144 = vblank
const MEM_LYC*: uint16 = 0xFF45
const MEM_DMA*: uint16 = 0xFF46
const MEM_BGP*: uint16 = 0xFF47
const MEM_OBP0*: uint16 = 0xFF48
const MEM_OBP1*: uint16 = 0xFF49
const MEM_WY*: uint16 = 0xFF4A
const MEM_WX*: uint16 = 0xFF4B

const MEM_BOOT*: uint16 = 0xFF50

const MEM_IE*: uint16 = 0xFFFF

const INTERRUPT_VBLANK*: uint8 = 1 shl 0
const INTERRUPT_STAT*: uint8 = 1 shl 1
const INTERRUPT_TIMER*: uint8 = 1 shl 2
const INTERRUPT_SERIAL*: uint8 = 1 shl 3
const INTERRUPT_JOYPAD*: uint8 = 1 shl 4
