<?php

declare(strict_types=1);

class Mem
{
    public static int $VBLANK_HANDLER = 0x40;
    public static int $LCD_HANDLER = 0x48;
    public static int $TIMER_HANDLER = 0x50;
    public static int $SERIAL_HANDLER = 0x58;
    public static int $JOYPAD_HANDLER = 0x60;

    public static int $TILE_DATA = 0x8000;
    public static int $MAP_0 = 0x9800;
    public static int $MAP_1 = 0x9C00;
    public static int $OAM_BASE = 0xFE00;

    public static int $JOYP = 0xFF00;

    public static int $SB = 0xFF01; // Serial Data
    public static int $SC = 0xFF02; // Serial Control

    public static int $DIV = 0xFF04;
    public static int $TIMA = 0xFF05;
    public static int $TMA = 0xFF06;
    public static int $TAC = 0xFF07;

    public static int $IF = 0xFF0F;

    public static int $NR10 = 0xFF10;
    public static int $NR11 = 0xFF11;
    public static int $NR12 = 0xFF12;
    public static int $NR13 = 0xFF13;
    public static int $NR14 = 0xFF14;

    public static int $NR20 = 0xFF15;
    public static int $NR21 = 0xFF16;
    public static int $NR22 = 0xFF17;
    public static int $NR23 = 0xFF18;
    public static int $NR24 = 0xFF19;

    public static int $NR30 = 0xFF1A;
    public static int $NR31 = 0xFF1B;
    public static int $NR32 = 0xFF1C;
    public static int $NR33 = 0xFF1D;
    public static int $NR34 = 0xFF1E;

    public static int $NR40 = 0xFF1F;
    public static int $NR41 = 0xFF20;
    public static int $NR42 = 0xFF21;
    public static int $NR43 = 0xFF22;
    public static int $NR44 = 0xFF23;

    public static int $NR50 = 0xFF24;
    public static int $NR51 = 0xFF25;
    public static int $NR52 = 0xFF26;

    public static int $LCDC = 0xFF40;
    public static int $STAT = 0xFF41;
    public static int $SCY = 0xFF42; // SCROLL_Y
    public static int $SCX = 0xFF43; // SCROLL_X
    public static int $LY = 0xFF44;  // LY aka currently drawn line, 0-153, >144 = vblank
    public static int $LYC = 0xFF45;
    public static int $DMA = 0xFF46;
    public static int $BGP = 0xFF47;
    public static int $OBP0 = 0xFF48;
    public static int $OBP1 = 0xFF49;
    public static int $WY = 0xFF4A;
    public static int $WX = 0xFF4B;

    public static int $BOOT = 0xFF50;

    public static int $IE = 0xFFFF;
}

enum Interrupt: int
{
    case VBLANK = 1 << 0;
    case STAT = 1 << 1;
    case TIMER = 1 << 2;
    case SERIAL = 1 << 3;
    case JOYPAD = 1 << 4;
}
