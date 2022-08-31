//const Joypad = struct {
//    MODE_BUTTONS: u8 = 1 << 5;
//    MODE_DPAD: u8 = 1 << 4;

pub const Mem = struct {
    pub const VBlankHandler: u16 = 0x40;
    pub const LcdHandler: u16 = 0x48;
    pub const TimerHandler: u16 = 0x50;
    pub const SerialHandler: u16 = 0x58;
    pub const JoypadHandler: u16 = 0x60;

    pub const TileData: u16 = 0x8000;
    pub const Map0: u16 = 0x9800;
    pub const Map1: u16 = 0x9C00;
    pub const OamBase: u16 = 0xFE00;

    pub const JOYP: u16 = 0xFF00;
    pub const BOOT: u16 = 0xFF50;

    _SB: u16 = 0xFF01, // Serial Data
    _SC: u16 = 0xFF02, // Serial Control

    DIV: u16 = 0xFF04,
    TIMA: u16 = 0xFF05,
    TMA: u16 = 0xFF06,
    TAC: u16 = 0xFF07,

    IF: u16 = 0xFF0F,

    NR10: u16 = 0xFF10,
    NR11: u16 = 0xFF11,
    NR12: u16 = 0xFF12,
    NR13: u16 = 0xFF13,
    NR14: u16 = 0xFF14,

    NR20: u16 = 0xFF15,
    NR21: u16 = 0xFF16,
    NR22: u16 = 0xFF17,
    NR23: u16 = 0xFF18,
    NR24: u16 = 0xFF19,

    NR30: u16 = 0xFF1A,
    NR31: u16 = 0xFF1B,
    NR32: u16 = 0xFF1C,
    NR33: u16 = 0xFF1D,
    NR34: u16 = 0xFF1E,

    NR40: u16 = 0xFF1F,
    NR41: u16 = 0xFF20,
    NR42: u16 = 0xFF21,
    NR43: u16 = 0xFF22,
    NR44: u16 = 0xFF23,

    NR50: u16 = 0xFF24,
    NR51: u16 = 0xFF25,
    NR52: u16 = 0xFF26,
    LCDC: u16 = 0xFF40,
    STAT: u16 = 0xFF41,
    SCY: u16 = 0xFF42, // SCROLL_Y
    SCX: u16 = 0xFF43, // SCROLL_X
    LY: u16 = 0xFF44, // LY aka currently drawn line; 0-153; >144 = vblank
    LYC: u16 = 0xFF45,
    DMA: u16 = 0xFF46,
    BGP: u16 = 0xFF47,
    OBP0: u16 = 0xFF48,
    OBP1: u16 = 0xFF49,
    WY: u16 = 0xFF4A,
    WX: u16 = 0xFF4B,
    BOOT: u16 = 0xFF50,

    IE: u16 = 0xFFFF,
};

pub const Interrupt = struct {
    pub const VBLANK: u8 = 1 << 0;
    pub const STAT: u8 = 1 << 1;
    pub const TIMER: u8 = 1 << 2;
    pub const SERIAL: u8 = 1 << 3;
    pub const JOYPAD: u8 = 1 << 4;
};
