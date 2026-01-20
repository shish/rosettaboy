export enum Mem {
    VBlankHandler = 0x40,
    LcdHandler = 0x48,
    TimerHandler = 0x50,
    SerialHandler = 0x58,
    JoypadHandler = 0x60,

    TileData = 0x8000,
    Map0 = 0x9800,
    Map1 = 0x9c00,
    OamBase = 0xfe00,

    JOYP = 0xff00,

    _SB = 0xff01, // Serial Data
    _SC = 0xff02, // Serial Control

    DIV = 0xff04,
    TIMA = 0xff05,
    TMA = 0xff06,
    TAC = 0xff07,

    IF = 0xff0f,

    NR10 = 0xff10,
    /*
    NR11 = 0xFF11,
    NR12 = 0xFF12,
    NR13 = 0xFF13,
    NR14 = 0xFF14,

    NR20 = 0xFF15,
    NR21 = 0xFF16,
    NR22 = 0xFF17,
    NR23 = 0xFF18,
    NR24 = 0xFF19,

    NR30 = 0xFF1A,
    NR31 = 0xFF1B,
    NR32 = 0xFF1C,
    NR33 = 0xFF1D,
    NR34 = 0xFF1E,

    NR40 = 0xFF1F,
    NR41 = 0xFF20,
    NR42 = 0xFF21,
    NR43 = 0xFF22,
    NR44 = 0xFF23,

    NR50 = 0xFF24,
    NR51 = 0xFF25,
    NR52 = 0xFF26,
    */
    LCDC = 0xff40,
    STAT = 0xff41,
    SCY = 0xff42, // SCROLL_Y
    SCX = 0xff43, // SCROLL_X
    LY = 0xff44, // LY aka currently drawn line, 0-153, >144 = vblank
    LYC = 0xff45,
    DMA = 0xff46,
    BGP = 0xff47,
    OBP0 = 0xff48,
    OBP1 = 0xff49,
    WY = 0xff4a,
    WX = 0xff4b,
    BOOT = 0xff50,

    IE = 0xffff,
}

export enum Interrupt {
    VBLANK = 1 << 0,
    STAT = 1 << 1,
    TIMER = 1 << 2,
    SERIAL = 1 << 3,
    JOYPAD = 1 << 4,
}
