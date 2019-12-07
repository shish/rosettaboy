#ifndef SPIGOT_CART_H
#define SPIGOT_CART_H

#include <cstdint>

#include "consts.h"

class Cart {
public:
    unsigned char *data;
    unsigned char *ram = nullptr;

    // u8 rsts[0x100];
    // u8 init[0x4];
    u8 logo[48];
    char name[15];
    bool is_gbc;
    u16 licensee;
    bool is_sgb;
    CartType cart_type;
    u32 rom_size;
    u32 ram_size;
    Destination destination;
    OldLicensee old_licensee;
    u8 rom_version;
    u8 complement_check;
    u16 checksum;

    Cart(const char *filename);

private:
    bool debug = false;
};

#endif //SPIGOT_CART_H
