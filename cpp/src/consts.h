#ifndef ROSETTABOY_CONSTS_H
#define ROSETTABOY_CONSTS_H

#include <exception>
#include <string>

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

typedef signed char i8;
typedef signed short i16;
typedef signed int i32;

namespace Mem {
    const u16 VBLANK_HANDLER = 0x40;
    const u16 LCD_HANDLER = 0x48;
    const u16 TIMER_HANDLER = 0x50;
    const u16 SERIAL_HANDLER = 0x58;
    const u16 JOYPAD_HANDLER = 0x60;

    const u16 TILE_DATA = 0x8000;
    const u16 MAP_0 = 0x9800;
    const u16 MAP_1 = 0x9C00;
    const u16 OAM_BASE = 0xFE00;

    const u16 JOYP = 0xFF00;

    const u16 SB = 0xFF01; // Serial Data
    const u16 SC = 0xFF02; // Serial Control

    const u16 DIV = 0xFF04;
    const u16 TIMA = 0xFF05;
    const u16 TMA = 0xFF06;
    const u16 TAC = 0xFF07;

    const u16 IF = 0xFF0F;

    const u16 NR10 = 0xFF10;
    const u16 NR11 = 0xFF11;
    const u16 NR12 = 0xFF12;
    const u16 NR13 = 0xFF13;
    const u16 NR14 = 0xFF14;

    const u16 NR20 = 0xFF15;
    const u16 NR21 = 0xFF16;
    const u16 NR22 = 0xFF17;
    const u16 NR23 = 0xFF18;
    const u16 NR24 = 0xFF19;

    const u16 NR30 = 0xFF1A;
    const u16 NR31 = 0xFF1B;
    const u16 NR32 = 0xFF1C;
    const u16 NR33 = 0xFF1D;
    const u16 NR34 = 0xFF1E;

    const u16 NR40 = 0xFF1F;
    const u16 NR41 = 0xFF20;
    const u16 NR42 = 0xFF21;
    const u16 NR43 = 0xFF22;
    const u16 NR44 = 0xFF23;

    const u16 NR50 = 0xFF24;
    const u16 NR51 = 0xFF25;
    const u16 NR52 = 0xFF26;

    const u16 LCDC = 0xFF40;
    const u16 STAT = 0xFF41;
    const u16 SCY = 0xFF42; // SCROLL_Y
    const u16 SCX = 0xFF43; // SCROLL_X
    const u16 LY = 0xFF44;  // LY aka currently drawn line, 0-153, >144 = vblank
    const u16 LYC = 0xFF45;
    const u16 DMA = 0xFF46;
    const u16 BGP = 0xFF47;
    const u16 OBP0 = 0xFF48;
    const u16 OBP1 = 0xFF49;
    const u16 WY = 0xFF4A;
    const u16 WX = 0xFF4B;

    const u16 BOOT = 0xFF50;

    const u16 IE = 0xFFFF;
} // namespace Mem

namespace Interrupt {
    enum Interrupt {
        VBLANK = 1 << 0,
        STAT = 1 << 1,
        TIMER = 1 << 2,
        SERIAL = 1 << 3,
        JOYPAD = 1 << 4,
    };
}

#endif // ROSETTABOY_CONSTS_H
