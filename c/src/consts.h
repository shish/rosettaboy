#ifndef ROSETTABOY_CONSTS_H
#define ROSETTABOY_CONSTS_H

#include <stdbool.h>
#include <stdint.h>

#if defined(__GNUC__) && __GNUC__ >= 3
#define HAVE_NORETURN
#define ROSETTABOY_NORETURN __attribute__((noreturn))
#define ROSETTABOY_ATTR_PRINTF(a1, a2) __attribute__((format(__printf__, a1, a2)))
#else
#define ROSETTABOY_NORETURN
#define ROSETTABOY_ATTR_PRINTF(a1, a2)
#endif

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;

typedef int8_t i8;
typedef int16_t i16;
typedef int32_t i32;

static const u16 MEM_VBLANK_HANDLER = 0x40;
static const u16 MEM_LCD_HANDLER = 0x48;
static const u16 MEM_TIMER_HANDLER = 0x50;
static const u16 MEM_SERIAL_HANDLER = 0x58;
static const u16 MEM_JOYPAD_HANDLER = 0x60;

static const u16 MEM_TILE_DATA = 0x8000;
static const u16 MEM_MAP_0 = 0x9800;
static const u16 MEM_MAP_1 = 0x9C00;
static const u16 MEM_OAM_BASE = 0xFE00;

static const u16 MEM_JOYP = 0xFF00;

static const u16 MEM_SB = 0xFF01; // Serial Data
static const u16 MEM_SC = 0xFF02; // Serial Control

static const u16 MEM_DIV = 0xFF04;
static const u16 MEM_TIMA = 0xFF05;
static const u16 MEM_TMA = 0xFF06;
static const u16 MEM_TAC = 0xFF07;

static const u16 MEM_IF = 0xFF0F;

static const u16 MEM_NR10 = 0xFF10;
static const u16 MEM_NR11 = 0xFF11;
static const u16 MEM_NR12 = 0xFF12;
static const u16 MEM_NR13 = 0xFF13;
static const u16 MEM_NR14 = 0xFF14;

static const u16 MEM_NR20 = 0xFF15;
static const u16 MEM_NR21 = 0xFF16;
static const u16 MEM_NR22 = 0xFF17;
static const u16 MEM_NR23 = 0xFF18;
static const u16 MEM_NR24 = 0xFF19;

static const u16 MEM_NR30 = 0xFF1A;
static const u16 MEM_NR31 = 0xFF1B;
static const u16 MEM_NR32 = 0xFF1C;
static const u16 MEM_NR33 = 0xFF1D;
static const u16 MEM_NR34 = 0xFF1E;

static const u16 MEM_NR40 = 0xFF1F;
static const u16 MEM_NR41 = 0xFF20;
static const u16 MEM_NR42 = 0xFF21;
static const u16 MEM_NR43 = 0xFF22;
static const u16 MEM_NR44 = 0xFF23;

static const u16 MEM_NR50 = 0xFF24;
static const u16 MEM_NR51 = 0xFF25;
static const u16 MEM_NR52 = 0xFF26;

static const u16 MEM_LCDC = 0xFF40;
static const u16 MEM_STAT = 0xFF41;
static const u16 MEM_SCY = 0xFF42; // SCROLL_Y
static const u16 MEM_SCX = 0xFF43; // SCROLL_X
static const u16 MEM_LY = 0xFF44;  // LY aka currently drawn line, 0-153, >144 = vblank
static const u16 MEM_LYC = 0xFF45;
static const u16 MEM_DMA = 0xFF46;
static const u16 MEM_BGP = 0xFF47;
static const u16 MEM_OBP0 = 0xFF48;
static const u16 MEM_OBP1 = 0xFF49;
static const u16 MEM_WY = 0xFF4A;
static const u16 MEM_WX = 0xFF4B;

static const u16 MEM_BOOT = 0xFF50;

static const u16 MEM_IE = 0xFFFF;

enum Interrupt {
    INTERRUPT_VBLANK = 1 << 0,
    INTERRUPT_STAT = 1 << 1,
    INTERRUPT_TIMER = 1 << 2,
    INTERRUPT_SERIAL = 1 << 3,
    INTERRUPT_JOYPAD = 1 << 4,
};

#endif // ROSETTABOY_CONSTS_H
