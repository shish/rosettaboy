#include "ram.h"

/**
 * A minimal boot ROM which just sets values the same as
 * the canonical ROM and then gets out of the way - no
 * logo scrolling or DRM.
 */
u8 BOOT[0x100] = {
    // clang-format off
    // prod memory
    0x31, 0xFE, 0xFF, // LD SP,$FFFE

    // enable LCD
    0x3E, 0x91, // LD A,$91
    0xE0, 0x40, // LDH [MEM_LCDC], A

    // set flags
    0x3E, 0x01, // LD A,$01
    0xCB, 0x7F, // BIT 7,A (sets Z,n,H)
    0x37,       // SCF (sets C)

    // set registers
    0x3E, 0x01, // LD A,$01
    0x06, 0x00, // LD B,$00
    0x0E, 0x13, // LD C,$13
    0x16, 0x00, // LD D,$00
    0x1E, 0xD8, // LD E,$D8
    0x26, 0x01, // LD H,$01
    0x2E, 0x4D, // LD L,$4D

    // skip to the end of the bootloader
    0xC3, 0xFD, 0x00, // JP 0x00FD
    // clang-format off
};

void ram_ctor(struct RAM *self, struct Cart *cart, bool debug) {
    *self = (struct RAM) {
        .debug = debug,
        .ram_enable = false,
        .ram_bank_mode = false,
        .rom_bank_low = 1,
        .rom_bank_high = 0,
        .rom_bank = 1,
        .ram_bank = 0,
        .cart = cart,
        .boot = BOOT,
    };

    // this instruction must be at the end of ROM --
    // after these finish executing, PC needs to be 0x100
    BOOT[0xFE] = 0xE0; // LDH 50,A (disable boot rom)
    BOOT[0xFF] = 0x50;

    // Load a real bootloader if available
    FILE *fp = fopen("boot.gb", "rb");
    if(fp) {
        fread(&BOOT, 1, 0x100, fp);
        fclose(fp);

        // NOP the DRM
        BOOT[0xE9] = 0x00;
        BOOT[0xEA] = 0x00;
        BOOT[0xFA] = 0x00;
        BOOT[0xFB] = 0x00;
    }
}

void ram_dump(struct RAM *self) {
    FILE *fp = fopen("mem.dat", "wb");
    fwrite(self->data, sizeof(u8), 0xFFFF + 1, fp);
    fclose(fp);
}
