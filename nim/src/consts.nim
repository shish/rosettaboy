const Mem_VBlankHandler*: uint16 = 0x40
const Mem_LcdHandler*: uint16 = 0x48
const Mem_TimerHandler*: uint16 = 0x50
const Mem_SerialHandler*: uint16 = 0x58
const Mem_JoypadHandler*: uint16 = 0x60


const Mem_TILE_DATA*: uint16 = 0x8000
const Mem_MAP_0*: uint16 = 0x9800
const Mem_MAP_1*: uint16 = 0x9C00
const Mem_OAM_BASE*: uint16 = 0xFE00

const Mem_JOYP*: uint16 = 0xFF00

const Mem_SB*: uint16 = 0xFF01 # Serial Data
const Mem_SC*: uint16 = 0xFF02 # Serial Control

const Mem_DIV*: uint16 = 0xFF04
const Mem_TIMA*: uint16 = 0xFF05
const Mem_TMA*: uint16 = 0xFF06
const Mem_TAC*: uint16 = 0xFF07

const Mem_IF*: uint16 = 0xFF0F

const Mem_NR10*: uint16 = 0xFF10
const Mem_NR11*: uint16 = 0xFF11
const Mem_NR12*: uint16 = 0xFF12
const Mem_NR13*: uint16 = 0xFF13
const Mem_NR14*: uint16 = 0xFF14

const Mem_NR20*: uint16 = 0xFF15
const Mem_NR21*: uint16 = 0xFF16
const Mem_NR22*: uint16 = 0xFF17
const Mem_NR23*: uint16 = 0xFF18
const Mem_NR24*: uint16 = 0xFF19

const Mem_NR30*: uint16 = 0xFF1A
const Mem_NR31*: uint16 = 0xFF1B
const Mem_NR32*: uint16 = 0xFF1C
const Mem_NR33*: uint16 = 0xFF1D
const Mem_NR34*: uint16 = 0xFF1E

const Mem_NR40*: uint16 = 0xFF1F
const Mem_NR41*: uint16 = 0xFF20
const Mem_NR42*: uint16 = 0xFF21
const Mem_NR43*: uint16 = 0xFF22
const Mem_NR44*: uint16 = 0xFF23

const Mem_NR50*: uint16 = 0xFF24
const Mem_NR51*: uint16 = 0xFF25
const Mem_NR52*: uint16 = 0xFF26

const Mem_LCDC*: uint16 = 0xFF40
const Mem_STAT*: uint16 = 0xFF41
const Mem_SCY*: uint16 = 0xFF42 # SCROLL_Y
const Mem_SCX*: uint16 = 0xFF43 # SCROLL_X
const Mem_LY*: uint16 = 0xFF44  # LY aka currently drawn line, 0-153, >144 = vblank
const Mem_LYC*: uint16 = 0xFF45
const Mem_DMA*: uint16 = 0xFF46
const Mem_BGP*: uint16 = 0xFF47
const Mem_OBP0*: uint16 = 0xFF48
const Mem_OBP1*: uint16 = 0xFF49
const Mem_WY*: uint16 = 0xFF4A
const Mem_WX*: uint16 = 0xFF4B

const Mem_BOOT*: uint16 = 0xFF50

const Mem_IE*: uint16 = 0xFFFF

const Interrupt_VBLANK*: uint8 = 1 shl 0
const Interrupt_STAT*: uint8 = 1 shl 1
const Interrupt_TIMER*: uint8 = 1 shl 2
const Interrupt_SERIAL*: uint8 = 1 shl 3
const Interrupt_JOYPAD*: uint8 = 1 shl 4
