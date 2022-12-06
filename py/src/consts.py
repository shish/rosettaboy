import typing as t

u8 = int
u16 = int
i8 = int


class Mem:
    VBLANK_HANDLER: t.Final[u16] = 0x40
    LCD_HANDLER: t.Final[u16] = 0x48
    TIMER_HANDLER: t.Final[u16] = 0x50
    SERIAL_HANDLER: t.Final[u16] = 0x58
    JOYPAD_HANDLER: t.Final[u16] = 0x60

    TILE_DATA: t.Final[u16] = 0x8000
    MAP_0: t.Final[u16] = 0x9800
    MAP_1: t.Final[u16] = 0x9C00
    OAM_BASE: t.Final[u16] = 0xFE00

    JOYP: t.Final[u16] = 0xFF00

    SB: t.Final[u16] = 0xFF01  # Serial Data
    SC: t.Final[u16] = 0xFF02  # Serial Control

    DIV: t.Final[u16] = 0xFF04
    TIMA: t.Final[u16] = 0xFF05
    TMA: t.Final[u16] = 0xFF06
    TAC: t.Final[u16] = 0xFF07

    IF: t.Final[u16] = 0xFF0F

    NR10: t.Final[u16] = 0xFF10
    NR11: t.Final[u16] = 0xFF11
    NR12: t.Final[u16] = 0xFF12
    NR13: t.Final[u16] = 0xFF13
    NR14: t.Final[u16] = 0xFF14

    NR20: t.Final[u16] = 0xFF15
    NR21: t.Final[u16] = 0xFF16
    NR22: t.Final[u16] = 0xFF17
    NR23: t.Final[u16] = 0xFF18
    NR24: t.Final[u16] = 0xFF19

    NR30: t.Final[u16] = 0xFF1A
    NR31: t.Final[u16] = 0xFF1B
    NR32: t.Final[u16] = 0xFF1C
    NR33: t.Final[u16] = 0xFF1D
    NR34: t.Final[u16] = 0xFF1E

    NR40: t.Final[u16] = 0xFF1F
    NR41: t.Final[u16] = 0xFF20
    NR42: t.Final[u16] = 0xFF21
    NR43: t.Final[u16] = 0xFF22
    NR44: t.Final[u16] = 0xFF23

    NR50: t.Final[u16] = 0xFF24
    NR51: t.Final[u16] = 0xFF25
    NR52: t.Final[u16] = 0xFF26

    LCDC: t.Final[u16] = 0xFF40
    STAT: t.Final[u16] = 0xFF41
    SCY: t.Final[u16] = 0xFF42  # SCROLL_Y
    SCX: t.Final[u16] = 0xFF43  # SCROLL_X
    LY: t.Final[u16] = 0xFF44  # LY aka currently drawn line 0-153 >144 = vblank
    LYC: t.Final[u16] = 0xFF45
    DMA: t.Final[u16] = 0xFF46
    BGP: t.Final[u16] = 0xFF47
    OBP0: t.Final[u16] = 0xFF48
    OBP1: t.Final[u16] = 0xFF49
    WY: t.Final[u16] = 0xFF4A
    WX: t.Final[u16] = 0xFF4B

    BOOT: t.Final[u16] = 0xFF50

    IE: t.Final[u16] = 0xFFFF


class Interrupt:
    VBLANK: t.Final[u8] = 1 << 0
    STAT: t.Final[u8] = 1 << 1
    TIMER: t.Final[u8] = 1 << 2
    SERIAL: t.Final[u8] = 1 << 3
    JOYPAD: t.Final[u8] = 1 << 4
