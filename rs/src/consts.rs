use bitflags::bitflags;

pub enum Mem {
    VBlankHandler = 0x40,
    LcdHandler = 0x48,
    TimerHandler = 0x50,
    SerialHandler = 0x58,
    JoypadHandler = 0x60,

    TileData = 0x8000,
    Map0 = 0x9800,
    Map1 = 0x9C00,
    OamBase = 0xFE00,

    JOYP = 0xFF00,

    _SB = 0xFF01, // Serial Data
    _SC = 0xFF02, // Serial Control

    DIV = 0xFF04,
    TIMA = 0xFF05,
    TMA = 0xFF06,
    TAC = 0xFF07,

    IF = 0xFF0F,

    NR10 = 0xFF10,
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
    LCDC = 0xFF40,
    STAT = 0xFF41,
    SCY = 0xFF42, // SCROLL_Y
    SCX = 0xFF43, // SCROLL_X
    LY = 0xFF44,  // LY aka currently drawn line, 0-153, >144 = vblank
    LYC = 0xFF45,
    DMA = 0xFF46,
    BGP = 0xFF47,
    OBP0 = 0xFF48,
    OBP1 = 0xFF49,
    WY = 0xFF4A,
    WX = 0xFF4B,
    BOOT = 0xFF50,

    IE = 0xFFFF,
}
impl From<Mem> for u16 {
    fn from(m: Mem) -> u16 {
        return m as u16;
    }
}

bitflags! {
    #[derive(Copy, Clone)]
    pub struct Interrupt: u8 {
        const VBLANK = 1<<0;
        const STAT = 1<<1;
        const TIMER = 1<<2;
        const SERIAL = 1<<3;
        const JOYPAD = 1<<4;
    }
}
