#ifndef ROSETTABOY_CART_H
#define ROSETTABOY_CART_H

#include <cstdint>

#include "consts.h"

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

class Cart {
public:
    unsigned char *data;
    unsigned char *ram = nullptr;

    u8 logo[48];
    char name[16];
    bool is_gbc;
    u16 licensee;
    bool is_sgb;
    CartType cart_type;
    u32 rom_size;
    u32 ram_size;
    u8 destination;
    u8 old_licensee;
    u8 rom_version;
    u8 complement_check;
    u16 checksum;

    Cart(const char *filename);

private:
    bool debug = false;
};

#endif // ROSETTABOY_CART_H
