#ifndef SPIGOT_CONSTS_H
#define SPIGOT_CONSTS_H

#include <string>

typedef unsigned char 		u8;
typedef unsigned short 		u16;
typedef unsigned int        u32;

typedef char 				i8;
typedef short 				i16;
typedef int                 i32;


static u16 VRAM_BASE = 0x8000;
static u16 TILE_DATA = 0x8000;
static u16 BACKGROUND_MAP_0 = 0x9800;
static u16 BACKGROUND_MAP_1 = 0x9C00;
static u16 WINDOW_MAP_0 = 0x9800;
static u16 WINDOW_MAP_1 = 0x9C00;
static u16 OAM_BASE = 0xFE00;


// It's too easy to make a subtle typo when
// trying to type these by hand... like 95%
// of bugs in development have been "missing
// a zero" or "used 0x instead of 0b" >.>
enum Bits {
    BIT_7 = 0b10000000,
    BIT_6 = 0b01000000,
    BIT_5 = 0b00100000,
    BIT_4 = 0b00010000,
    BIT_3 = 0b00001000,
    BIT_2 = 0b00000100,
    BIT_1 = 0b00000010,
    BIT_0 = 0b00000001,
};

enum CartType {
    ROM_ONLY = 0x00,
    ROM_MBC1 = 0x01,
    ROM_MBC1_RAM = 0x02,
    ROM_MBC1_RAM_BATT = 0x03,
    ROM_MBC2 = 0x05,
    ROM_MBC2_BATT = 0x06,
    ROM_RAM = 0x08,
    ROM_RAM_BATT = 0x09,
    ROM_MMM01 = 0x0B,
    ROM_MMM01_SRAM = 0x0C,
    ROM_MMM01_SRAM_BATT = 0x0D,
    ROM_MBC3_TIMER_BATT = 0x0F,
    ROM_MBC3_TIMER_RAM_BATT = 0x10,
    ROM_MBC3 = 0x11,
    ROM_MBC3_RAM = 0x12,
    ROM_MBC3_RAM_BATT = 0x13,
    ROM_MBC5 = 0x19,
    ROM_MBC5_RAM = 0x1A,
    ROM_MBC5_RAM_BATT = 0x1B,
    ROM_MBC5_RUMBLE = 0x1C,
    ROM_MBC5_RUMBLE_RAM = 0x1D,
    ROM_MBC5_RUMBLE_RAM_BATT = 0x1E,
    POCKET_CAMERA = 0x1F,
    BANDAI_TAMA5 = 0xFD,
    HUDSON_HUC3 = 0xFE,
    HUDSON_HUC1 = 0xFF,
};

enum Destination {
    JP = 0,
    OTHER = 1,
};

enum OldLicensee {
    MAYBE_NOBODY = 0x00,
    MAYBE_NINTENDO = 0x01,
    CHECK_NEW = 0x33,
    ACCOLADE = 0x79,
    KONAMI = 0xA4,
};

static u8 OP_CYCLES[] = {
    1,3,2,2,1,1,2,1,5,2,2,2,1,1,2,1,
    0,3,2,2,1,1,2,1,3,2,2,2,1,1,2,1,
    2,3,2,2,1,1,2,1,2,2,2,2,1,1,2,1,
    2,3,2,2,3,3,3,1,2,2,2,2,1,1,2,1,
    1,1,1,1,1,1,2,1,1,1,1,1,1,1,2,1,
    1,1,1,1,1,1,2,1,1,1,1,1,1,1,2,1,
    1,1,1,1,1,1,2,1,1,1,1,1,1,1,2,1,
    2,2,2,2,2,2,0,2,1,1,1,1,1,1,2,1,
    1,1,1,1,1,1,2,1,1,1,1,1,1,1,2,1,
    1,1,1,1,1,1,2,1,1,1,1,1,1,1,2,1,
    1,1,1,1,1,1,2,1,1,1,1,1,1,1,2,1,
    1,1,1,1,1,1,2,1,1,1,1,1,1,1,2,1,
    2,3,3,4,3,4,2,4,2,4,3,0,3,6,2,4,
    2,3,3,0,3,4,2,4,2,4,3,0,3,0,2,4,
    3,3,2,0,0,4,2,4,4,1,4,0,0,0,2,4,
    3,3,2,1,0,4,2,4,3,2,4,1,0,0,2,4
};

static u8 OP_CB_CYCLES[] = {
    2,2,2,2,2,2,4,2,2,2,2,2,2,2,4,2,
    2,2,2,2,2,2,4,2,2,2,2,2,2,2,4,2,
    2,2,2,2,2,2,4,2,2,2,2,2,2,2,4,2,
    2,2,2,2,2,2,4,2,2,2,2,2,2,2,4,2,
    2,2,2,2,2,2,3,2,2,2,2,2,2,2,3,2,
    2,2,2,2,2,2,3,2,2,2,2,2,2,2,3,2,
    2,2,2,2,2,2,3,2,2,2,2,2,2,2,3,2,
    2,2,2,2,2,2,3,2,2,2,2,2,2,2,3,2,
    2,2,2,2,2,2,4,2,2,2,2,2,2,2,4,2,
    2,2,2,2,2,2,4,2,2,2,2,2,2,2,4,2,
    2,2,2,2,2,2,4,2,2,2,2,2,2,2,4,2,
    2,2,2,2,2,2,4,2,2,2,2,2,2,2,4,2,
    2,2,2,2,2,2,4,2,2,2,2,2,2,2,4,2,
    2,2,2,2,2,2,4,2,2,2,2,2,2,2,4,2,
    2,2,2,2,2,2,4,2,2,2,2,2,2,2,4,2,
    2,2,2,2,2,2,4,2,2,2,2,2,2,2,4,2
};

static u8 OP_ARG_TYPES[] = {
    //1 2 3 4 5 6 7 8 9 A B C D E F
    0,2,0,0,0,0,1,0,2,0,0,0,0,0,1,0, // 0
    1,2,0,0,0,0,1,0,3,0,0,0,0,0,1,0, // 1
    3,2,0,0,0,0,1,0,3,0,0,0,0,0,1,0, // 2
    3,2,0,0,0,0,1,0,3,0,0,0,0,0,1,0, // 3
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 4
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 5
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 6
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 7
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 8
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 9
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // A
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // B
    0,0,2,2,2,0,1,0,0,0,2,0,2,2,1,0, // C
    0,0,2,0,2,0,1,0,0,0,2,0,2,0,1,0, // D
    1,0,0,0,0,0,1,0,3,0,2,0,0,0,1,0, // E
    1,0,0,0,0,0,1,0,3,0,2,0,0,0,1,0, // F
};

static u8 OP_ARG_BYTES[] = {0,1,2,1};


static std::string OP_NAMES[] = {
    "NOP", "LD BC,$%04X", "LD [BC],A", "INC BC", "INC B", "DEC B", "LD B,$%02X", "RCLA", "LD [$%04X],SP",
    "ADD HL,BC", "LD A,[BC]", "DEC BC", "INC C", "DEC C", "LD C,$%02X", "RRCA", "STOP", "LD DE,$%04X",
    "LD [DE],A", "INC DE", "INC D", "DEC D", "LD D,$%02X", "RLA", "JR %+d", "ADD HL,DE", "LD A,[DE]",
    "DEC DE", "INC E", "DEC E", "LD E,$%02X", "RRA", "JR NZ,%+d", "LD HL,$%04X", "LD [HL+],A", "INC HL",
    "INC H", "DEC H", "LD H,$%02X", "DAA", "JR Z,%+d", "ADD HL,HL", "LD A,[HL+]", "DEC HL", "INC L",
    "DEC L", "LD L,$%02X", "CPL", "JR NC,%+d", "LD SP,$%04X", "LD [HL-],A", "INC SP", "INC [HL]",
    "DEC [HL]", "LD [HL],$%02X", "SCF", "JR C,%+d", "ADD HL,SP", "LD A,[HL-]", "DEC SP", "INC A",
    "DEC A", "LD A,$%02X", "CCF",
    "LD B,B", "LD B,C", "LD B,D", "LD B,E", "LD B,H", "LD B,L", "LD B,[HL]", "LD B,A",
    "LD C,B", "LD C,C", "LD C,D", "LD C,E", "LD C,H", "LD C,L", "LD C,[HL]", "LD C,A",
    "LD D,B", "LD D,C", "LD D,D", "LD D,E", "LD D,H", "LD D,L", "LD D,[HL]", "LD D,A",
    "LD E,B", "LD E,C", "LD E,D", "LD E,E", "LD E,H", "LD E,L", "LD E,[HL]", "LD E,A",
    "LD H,B", "LD H,C", "LD H,D", "LD H,E", "LD H,H", "LD H,L", "LD H,[HL]", "LD H,A",
    "LD L,B", "LD L,C", "LD L,D", "LD L,E", "LD L,H", "LD L,L", "LD L,[HL]", "LD L,A",
    "LD [HL],B", "LD [HL],C", "LD [HL],D", "LD [HL],E", "LD [HL],H", "LD [HL],L", "HALT", "LD [HL],A",
    "LD A,B", "LD A,C", "LD A,D", "LD A,E", "LD A,H", "LD A,L", "LD A,[HL]", "LD A,A",
    "ADD A,B", "ADD A,C", "ADD A,D", "ADD A,E", "ADD A,H", "ADD A,L", "ADD A,[HL]", "ADD A,A",
    "ADC A,B", "ADC A,C", "ADC A,D", "ADC A,E", "ADC A,H", "ADC A,L", "ADC A,[HL]", "ADC A,A",
    "SUB A,B", "SUB A,C", "SUB A,D", "SUB A,E", "SUB A,H", "SUB A,L", "SUB A,[HL]", "SUB A,A",
    "SBC A,B", "SBC A,C", "SBC A,D", "SBC A,E", "SBC A,H", "SBC A,L", "SBC A,[HL]", "SBC A,A",
    "AND B", "AND C", "AND D", "AND E", "AND H", "AND L", "AND [HL]", "AND A",
    "XOR B", "XOR C", "XOR D", "XOR E", "XOR H", "XOR L", "XOR [HL]", "XOR A",
    "OR B", "OR C", "OR D", "OR E", "OR H", "OR L", "OR [HL]", "OR A",
    "CP B", "CP C", "CP D", "CP E", "CP H", "CP L", "CP [HL]", "CP A",
    "RET NZ", "POP BC", "JP NZ,$%02X", "JP $%04X", "CALL NZ,$%04X", "PUSH BC", "ADD A,$%02X", "RST 00",
    "RET Z", "RET", "JP Z,$%02X", "ERR CB", "CALL Z,$%04X", "CALL $%04X", "ADC A,$%02X", "RST 08",
    "RET NC", "POP DE", "JP NC,$%02X", "ERR D3", "CALL NC,$%04X", "PUSH DE", "SUB A,$%02X", "RST 10",
    "RET C", "RETI", "JP C,$%02X", "ERR DB", "CALL C,$%04X", "ERR DD", "SBC A,$%02X", "RST 18",
    "LDH [$%02X],A", "POP HL", "LDH [C],A", "DBG", "ERR E4", "PUSH HL", "AND $%02X", "RST 20",
    "ADD SP %+d", "JP HL", "LD [$%04X],A", "ERR EB", "ERR EC", "ERR ED", "XOR $%02X", "RST 28",
    "LDH A,[$%02X]", "POP AF", "LDH A,[C]", "DI", "ERR F4", "PUSH AF", "OR $%02X", "RST 30",
    "LD HL,SP%+d", "LD SP,HL", "LD A,[$%04X]", "EI", "ERR FC", "ERR FD", "CP $%02X", "RST 38"
};

static std::string CB_OP_NAMES[] = {
    "RLC B", "RLC C", "RLC D", "RLC E", "RLC H", "RLC L", "RLC [HL]", "RLC A",
    "RRC B", "RRC C", "RRC D", "RRC E", "RRC H", "RRC L", "RRC [HL]", "RRC A",
    "RL B", "RL C", "RL D", "RL E", "RL H", "RL L", "RL [HL]", "RL A",
    "RR B", "RR C", "RR D", "RR E", "RR H", "RR L", "RR [HL]", "RR A",
    "SLA B", "SLA C", "SLA D", "SLA E", "SLA H", "SLA L", "SLA [HL]", "SLA A",
    "SRA B", "SRA C", "SRA D", "SRA E", "SRA H", "SRA L", "SRA [HL]", "SRA A",
    "SWAP B", "SWAP C", "SWAP D", "SWAP E", "SWAP H", "SWAP L", "SWAP [HL]", "SWAP A",
    "SRL B", "SRL C", "SRL D", "SRL E", "SRL H", "SRL L", "SRL [HL]", "SRL A",
    "BIT 0,B", "BIT 0,C", "BIT 0,D", "BIT 0,E", "BIT 0,H", "BIT 0,L", "BIT 0,[HL]", "BIT 0,A",
    "BIT 1,B", "BIT 1,C", "BIT 1,D", "BIT 1,E", "BIT 1,H", "BIT 1,L", "BIT 1,[HL]", "BIT 1,A",
    "BIT 2,B", "BIT 2,C", "BIT 2,D", "BIT 2,E", "BIT 2,H", "BIT 2,L", "BIT 2,[HL]", "BIT 2,A",
    "BIT 3,B", "BIT 3,C", "BIT 3,D", "BIT 3,E", "BIT 3,H", "BIT 3,L", "BIT 3,[HL]", "BIT 3,A",
    "BIT 4,B", "BIT 4,C", "BIT 4,D", "BIT 4,E", "BIT 4,H", "BIT 4,L", "BIT 4,[HL]", "BIT 4,A",
    "BIT 5,B", "BIT 5,C", "BIT 5,D", "BIT 5,E", "BIT 5,H", "BIT 5,L", "BIT 5,[HL]", "BIT 5,A",
    "BIT 6,B", "BIT 6,C", "BIT 6,D", "BIT 6,E", "BIT 6,H", "BIT 6,L", "BIT 6,[HL]", "BIT 6,A",
    "BIT 7,B", "BIT 7,C", "BIT 7,D", "BIT 7,E", "BIT 7,H", "BIT 7,L", "BIT 7,[HL]", "BIT 7,A",
    "RES 0,B", "RES 0,C", "RES 0,D", "RES 0,E", "RES 0,H", "RES 0,L", "RES 0,[HL]", "RES 0,A",
    "RES 1,B", "RES 1,C", "RES 1,D", "RES 1,E", "RES 1,H", "RES 1,L", "RES 1,[HL]", "RES 1,A",
    "RES 2,B", "RES 2,C", "RES 2,D", "RES 2,E", "RES 2,H", "RES 2,L", "RES 2,[HL]", "RES 2,A",
    "RES 3,B", "RES 3,C", "RES 3,D", "RES 3,E", "RES 3,H", "RES 3,L", "RES 3,[HL]", "RES 3,A",
    "RES 4,B", "RES 4,C", "RES 4,D", "RES 4,E", "RES 4,H", "RES 4,L", "RES 4,[HL]", "RES 4,A",
    "RES 5,B", "RES 5,C", "RES 5,D", "RES 5,E", "RES 5,H", "RES 5,L", "RES 5,[HL]", "RES 5,A",
    "RES 6,B", "RES 6,C", "RES 6,D", "RES 6,E", "RES 6,H", "RES 6,L", "RES 6,[HL]", "RES 6,A",
    "RES 7,B", "RES 7,C", "RES 7,D", "RES 7,E", "RES 7,H", "RES 7,L", "RES 7,[HL]", "RES 7,A",
    "SET 0,B", "SET 0,C", "SET 0,D", "SET 0,E", "SET 0,H", "SET 0,L", "SET 0,[HL]", "SET 0,A",
    "SET 1,B", "SET 1,C", "SET 1,D", "SET 1,E", "SET 1,H", "SET 1,L", "SET 1,[HL]", "SET 1,A",
    "SET 2,B", "SET 2,C", "SET 2,D", "SET 2,E", "SET 2,H", "SET 2,L", "SET 2,[HL]", "SET 2,A",
    "SET 3,B", "SET 3,C", "SET 3,D", "SET 3,E", "SET 3,H", "SET 3,L", "SET 3,[HL]", "SET 3,A",
    "SET 4,B", "SET 4,C", "SET 4,D", "SET 4,E", "SET 4,H", "SET 4,L", "SET 4,[HL]", "SET 4,A",
    "SET 5,B", "SET 5,C", "SET 5,D", "SET 5,E", "SET 5,H", "SET 5,L", "SET 5,[HL]", "SET 5,A",
    "SET 6,B", "SET 6,C", "SET 6,D", "SET 6,E", "SET 6,H", "SET 6,L", "SET 6,[HL]", "SET 6,A",
    "SET 7,B", "SET 7,C", "SET 7,D", "SET 7,E", "SET 7,H", "SET 7,L", "SET 7,[HL]", "SET 7,A"
};

enum IOMem {
    IO_JOYP = 0xFF00,
    
    IO_SB = 0xFF01, // Serial Data
    IO_SC = 0xFF02, // Serial Control

    IO_DIV = 0xFF04,
    IO_TIMA = 0xFF05,
    IO_TMA = 0xFF06,
    IO_TAC = 0xFF07,

    IO_IF = 0xFF0F,

    IO_NR10 = 0xFF10,
    IO_NR11 = 0xFF11,
    IO_NR12 = 0xFF12,
    IO_NR13 = 0xFF13,
    IO_NR14 = 0xFF14,

    IO_NR20 = 0xFF15,
    IO_NR21 = 0xFF16,
    IO_NR22 = 0xFF17,
    IO_NR23 = 0xFF18,
    IO_NR24 = 0xFF19,

    IO_NR30 = 0xFF1A,
    IO_NR31 = 0xFF1B,
    IO_NR32 = 0xFF1C,
    IO_NR33 = 0xFF1D,
    IO_NR34 = 0xFF1E,

    IO_NR40 = 0xFF1F,
    IO_NR41 = 0xFF20,
    IO_NR42 = 0xFF21,
    IO_NR43 = 0xFF22,
    IO_NR44 = 0xFF23,

    IO_NR50 = 0xFF24,
    IO_NR51 = 0xFF25,
    IO_NR52 = 0xFF26,

    IO_LCDC = 0xFF40,
    IO_STAT = 0xFF41,
    IO_SCY = 0xFF42,  // SCROLL_Y
    IO_SCX = 0xFF43,  // SCROLL_X
    IO_LY = 0xFF44,  // LY aka currently drawn line, 0-153, >144 = vblank
    IO_LYC = 0xFF45,
    IO_DMA = 0xFF46,
    IO_BGP = 0xFF47,
    IO_OBP0 = 0xFF48,
    IO_OBP1 = 0xFF49,
    IO_WY = 0xFF4A,
    IO_WX = 0xFF4B,

    IO_BOOT = 0xFF50,

    IO_IE = 0xFFFF,
};

enum LCDCFlag {
    LCDC_ENABLED = BIT_7,
    LCDC_WINDOW_MAP = BIT_6,
    LCDC_WINDOW_ENABLED = BIT_5,
    LCDC_DATA_SRC = BIT_4,
    LCDC_BG_MAP = BIT_3,
    LCDC_OBJ_SIZE = BIT_2,
    LCDC_OBJ_ENABLED = BIT_1,
    LCDC_BG_WIN_ENABLED = BIT_0,
};

enum STATFlag {
    STAT_LYC_INTERRUPT = BIT_6,
    STAT_OAM_INTERRUPT = BIT_5,
    STAT_VBLANK_INTERRUPT = BIT_4,
    STAT_HBLANK_INTERRUPT = BIT_3,
    STAT_LCY_EQUAL = BIT_2,
    STAT_MODE = BIT_1 | BIT_0,
};

enum STATMode {
    STAT_MODE_HBLANK = 0x00,
    STAT_MODE_VBLANK = 0x01,
    STAT_MODE_OAM = 0x02,
    STAT_MODE_DRAWING = 0x03,
};

enum Interrupt {
    INT_VBLANK = BIT_0,
    INT_STAT = BIT_1,
    INT_TIMER = BIT_2,
    INT_SERIAL = BIT_3,
    INT_JOYPAD = BIT_4,
};

enum JOYPFlag {
    JOYP_SELECT_BUTTONS = BIT_5,
    JOYP_SELECT_DPAD = BIT_4,
    JOYP_DOWN = BIT_3,
    JOYP_START = BIT_3,
    JOYP_UP = BIT_2,
    JOYP_SELECT = BIT_2,
    JOYP_LEFT = BIT_1,
    JOYP_B = BIT_1,
    JOYP_RIGHT = BIT_0,
    JOYP_A = BIT_0,
};

enum InterruptHandler {
    INT_VBLANK_HANDLER = 0x40,
    INT_LCD_HANDLER = 0x48,
    INT_TIMER_HANDLER = 0x50,
    INT_SERIAL_HANDLER = 0x58,
    INT_JOYPAD_HANDLER = 0x60,
};

#endif //SPIGOT_CONSTS_H
