<?php

class Mem {
    public static $VBLANK_HANDLER = 0x40;
    public static $LCD_HANDLER = 0x48;
    public static $TIMER_HANDLER = 0x50;
    public static $SERIAL_HANDLER = 0x58;
    public static $JOYPAD_HANDLER = 0x60;

    public static $TILE_DATA = 0x8000;
    public static $MAP_0 = 0x9800;
    public static $MAP_1 = 0x9C00;
    public static $OAM_BASE = 0xFE00;

    public static $JOYP = 0xFF00;

    public static $SB = 0xFF01; // Serial Data
    public static $SC = 0xFF02; // Serial Control

    public static $DIV = 0xFF04;
    public static $TIMA = 0xFF05;
    public static $TMA = 0xFF06;
    public static $TAC = 0xFF07;

    public static $IF = 0xFF0F;

    public static $NR10 = 0xFF10;
    public static $NR11 = 0xFF11;
    public static $NR12 = 0xFF12;
    public static $NR13 = 0xFF13;
    public static $NR14 = 0xFF14;

    public static $NR20 = 0xFF15;
    public static $NR21 = 0xFF16;
    public static $NR22 = 0xFF17;
    public static $NR23 = 0xFF18;
    public static $NR24 = 0xFF19;

    public static $NR30 = 0xFF1A;
    public static $NR31 = 0xFF1B;
    public static $NR32 = 0xFF1C;
    public static $NR33 = 0xFF1D;
    public static $NR34 = 0xFF1E;

    public static $NR40 = 0xFF1F;
    public static $NR41 = 0xFF20;
    public static $NR42 = 0xFF21;
    public static $NR43 = 0xFF22;
    public static $NR44 = 0xFF23;

    public static $NR50 = 0xFF24;
    public static $NR51 = 0xFF25;
    public static $NR52 = 0xFF26;

    public static $LCDC = 0xFF40;
    public static $STAT = 0xFF41;
    public static $SCY = 0xFF42; // SCROLL_Y
    public static $SCX = 0xFF43; // SCROLL_X
    public static $LY = 0xFF44;  // LY aka currently drawn line, 0-153, >144 = vblank
    public static $LYC = 0xFF45;
    public static $DMA = 0xFF46;
    public static $BGP = 0xFF47;
    public static $OBP0 = 0xFF48;
    public static $OBP1 = 0xFF49;
    public static $WY = 0xFF4A;
    public static $WX = 0xFF4B;

    public static $BOOT = 0xFF50;

    public static $IE = 0xFFFF;
}

class Interrupt {
    public static $VBLANK = 1 << 0;
    public static $STAT = 1 << 1;
    public static $TIMER = 1 << 2;
    public static $SERIAL = 1 << 3;
    public static $JOYPAD = 1 << 4;
}

