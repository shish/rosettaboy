import typing as t
import cython

if not cython.compiled:
    u8 = cython.uchar
    u16 = cython.ushort
    i8 = cython.char
    booli = bool


def as_u8(val: cython.int) -> u8:
    return val


def as_bool(val: cython.int) -> cython.bint:
    return 1 if val else 0


class _Mem:
    def __init__(self):
        self.VBLANK_HANDLER: u16 = 0x40
        self.LCD_HANDLER: u16 = 0x48
        self.TIMER_HANDLER: u16 = 0x50
        self.SERIAL_HANDLER: u16 = 0x58
        self.JOYPAD_HANDLER: u16 = 0x60

        self.TILE_DATA: u16 = 0x8000
        self.MAP_0: u16 = 0x9800
        self.MAP_1: u16 = 0x9C00
        self.OAM_BASE: u16 = 0xFE00

        self.JOYP: u16 = 0xFF00

        self.SB: u16 = 0xFF01  # Serial Data
        self.SC: u16 = 0xFF02  # Serial Control

        self.DIV: u16 = 0xFF04
        self.TIMA: u16 = 0xFF05
        self.TMA: u16 = 0xFF06
        self.TAC: u16 = 0xFF07

        self.IF_: u16 = 0xFF0F

        self.NR10: u16 = 0xFF10
        self.NR11: u16 = 0xFF11
        self.NR12: u16 = 0xFF12
        self.NR13: u16 = 0xFF13
        self.NR14: u16 = 0xFF14

        self.NR20: u16 = 0xFF15
        self.NR21: u16 = 0xFF16
        self.NR22: u16 = 0xFF17
        self.NR23: u16 = 0xFF18
        self.NR24: u16 = 0xFF19

        self.NR30: u16 = 0xFF1A
        self.NR31: u16 = 0xFF1B
        self.NR32: u16 = 0xFF1C
        self.NR33: u16 = 0xFF1D
        self.NR34: u16 = 0xFF1E

        self.NR40: u16 = 0xFF1F
        self.NR41: u16 = 0xFF20
        self.NR42: u16 = 0xFF21
        self.NR43: u16 = 0xFF22
        self.NR44: u16 = 0xFF23

        self.NR50: u16 = 0xFF24
        self.NR51: u16 = 0xFF25
        self.NR52: u16 = 0xFF26

        self.LCDC: u16 = 0xFF40
        self.STAT: u16 = 0xFF41
        self.SCY: u16 = 0xFF42  # SCROLL_Y
        self.SCX: u16 = 0xFF43  # SCROLL_X
        self.LY: u16 = 0xFF44  # LY aka currently drawn line 0-153 >144 = vblank
        self.LYC: u16 = 0xFF45
        self.DMA: u16 = 0xFF46
        self.BGP: u16 = 0xFF47
        self.OBP0: u16 = 0xFF48
        self.OBP1: u16 = 0xFF49
        self.WY: u16 = 0xFF4A
        self.WX: u16 = 0xFF4B

        self.BOOT: u16 = 0xFF50

        self.IE: u16 = 0xFFFF


Mem = _Mem()


class _Interrupt:
    def __init__(self):
        self.VBLANK: u8 = 1 << 0
        self.STAT: u8 = 1 << 1
        self.TIMER: u8 = 1 << 2
        self.SERIAL: u8 = 1 << 3
        self.JOYPAD: u8 = 1 << 4


Interrupt = _Interrupt()
