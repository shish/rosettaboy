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

    pub const SB: u16 = 0xFF01; // Serial Data
    pub const SC: u16 = 0xFF02; // Serial Control

    pub const DIV: u16 = 0xFF04;
    pub const TIMA: u16 = 0xFF05;
    pub const TMA: u16 = 0xFF06;
    pub const TAC: u16 = 0xFF07;

    pub const IF: u16 = 0xFF0F;

    pub const NR10: u16 = 0xFF10;
    pub const NR11: u16 = 0xFF11;
    pub const NR12: u16 = 0xFF12;
    pub const NR13: u16 = 0xFF13;
    pub const NR14: u16 = 0xFF14;

    pub const NR20: u16 = 0xFF15;
    pub const NR21: u16 = 0xFF16;
    pub const NR22: u16 = 0xFF17;
    pub const NR23: u16 = 0xFF18;
    pub const NR24: u16 = 0xFF19;

    pub const NR30: u16 = 0xFF1A;
    pub const NR31: u16 = 0xFF1B;
    pub const NR32: u16 = 0xFF1C;
    pub const NR33: u16 = 0xFF1D;
    pub const NR34: u16 = 0xFF1E;

    pub const NR40: u16 = 0xFF1F;
    pub const NR41: u16 = 0xFF20;
    pub const NR42: u16 = 0xFF21;
    pub const NR43: u16 = 0xFF22;
    pub const NR44: u16 = 0xFF23;

    pub const NR50: u16 = 0xFF24;
    pub const NR51: u16 = 0xFF25;
    pub const NR52: u16 = 0xFF26;
    pub const LCDC: u16 = 0xFF40;
    pub const STAT: u16 = 0xFF41;
    pub const SCY: u16 = 0xFF42; // SCROLL_Y
    pub const SCX: u16 = 0xFF43; // SCROLL_X
    pub const LY: u16 = 0xFF44; // LY aka currently drawn line; 0-153; >144 = vblank
    pub const LYC: u16 = 0xFF45;
    pub const DMA: u16 = 0xFF46;
    pub const BGP: u16 = 0xFF47;
    pub const OBP0: u16 = 0xFF48;
    pub const OBP1: u16 = 0xFF49;
    pub const WY: u16 = 0xFF4A;
    pub const WX: u16 = 0xFF4B;
    pub const BOOT: u16 = 0xFF50;

    pub const IE: u16 = 0xFFFF;
};

pub const Interrupt = struct {
    pub const VBLANK: u8 = 1 << 0;
    pub const STAT: u8 = 1 << 1;
    pub const TIMER: u8 = 1 << 2;
    pub const SERIAL: u8 = 1 << 3;
    pub const JOYPAD: u8 = 1 << 4;
};
