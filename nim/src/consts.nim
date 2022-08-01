const Mem_VBlankHandler*: uint16 = 0x40
const Mem_LcdHandler*: uint16 = 0x48
const Mem_TimerHandler*: uint16 = 0x50
const Mem_SerialHandler*: uint16 = 0x58
const Mem_JoypadHandler*: uint16 = 0x60

const Mem_OamBase*: uint16 = 0xFE00

const Mem_JOYP*: uint16 = 0xFF00
const Mem_DIV*: uint16 = 0xFF04
const Mem_TIMA*: uint16 = 0xFF05
const Mem_TMA*: uint16 = 0xFF06
const Mem_TAC*: uint16 = 0xFF07
const Mem_IF*: uint16 = 0xFF0F
const Mem_DMA*: uint16 = 0xFF46
const Mem_BOOT*: uint16 = 0xFF50
const Mem_IE*: uint16 = 0xFFFF

const Interrupt_VBLANK*: uint8 = 1 shl 0
const Interrupt_STAT*: uint8 = 1 shl 1
const Interrupt_TIMER*: uint8 = 1 shl 2
const Interrupt_SERIAL*: uint8 = 1 shl 3
const Interrupt_JOYPAD*: uint8 = 1 shl 4
