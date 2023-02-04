#ifndef ROSETTABOY_RAM_H
#define ROSETTABOY_RAM_H

#include "cart.h"
#include "consts.h"
#include "errors.h"

static const u16 ROM_BANK_SIZE = 0x4000;
static const u16 RAM_BANK_SIZE = 0x2000;

struct RAM {
    struct Cart *cart;
    bool ram_enable;
    bool ram_bank_mode;
    u8 rom_bank_low;
    u8 rom_bank_high;
    u8 rom_bank;
    u8 ram_bank;
    u8 *boot;
    bool debug;
    u8 data[0xFFFF + 1];
};

void ram_ctor(struct RAM *self, struct Cart *cart, bool debug);
void ram_dump(struct RAM *self);

static inline u8 ram_get(struct RAM *self, u16 addr) {
    u8 val = self->data[addr];
    switch (addr) {
        case 0x0000 ... 0x3FFF: {
            // ROM bank 0
            if (self->data[MEM_BOOT] == 0 && addr < 0x0100) {
                val = self->boot[addr];
            } else {
                val = self->cart->data[addr];
            }
            break;
        }
        case 0x4000 ... 0x7FFF: {
            // Switchable ROM bank
            int bank = self->rom_bank * ROM_BANK_SIZE;
            int offset = addr - 0x4000;
            // printf("fetching %04X from bank %04X (total = %04X)\n", offset, bank, offset + bank);
            val = self->cart->data[bank + offset];
            break;
        }
        case 0x8000 ... 0x9FFF:
            // VRAM
            break;
        case 0xA000 ... 0xBFFF: {
            // 8KB Switchable RAM bank
            if (!self->ram_enable) {
                printf("ERR: Reading from external ram while disabled: %04X\n", addr);
                return 0;
            }
            int bank = self->ram_bank * RAM_BANK_SIZE;
            int offset = addr - 0xA000;
            if (bank + offset >= self->cart->ram_size) {
                invalid_ram_read_err(self->ram_bank, offset, self->cart->ram_size);
            }
            val = self->cart->ram[bank + offset];
            break;
        }
        case 0xC000 ... 0xCFFF:
            // work RAM, bank 0
            break;
        case 0xD000 ... 0xDFFF:
            // work RAM, bankable in CGB
            break;
        case 0xE000 ... 0xFDFF: {
            // ram[E000-FE00] mirrors ram[C000-DE00]
            val = self->data[addr - 0x2000];
            break;
        }
        case 0xFE00 ... 0xFE9F:
            // Sprite attribute table
            break;
        case 0xFEA0 ... 0xFEFF:
            // Unusable
            val = 0xFF;
            break;
        case 0xFF00 ... 0xFF7F:
            // GPU Registers
            break;
        case 0xFF80 ... 0xFFFE:
            // High RAM
            break;
        case 0xFFFF:
            // IE Register
            break;
    }

    if (self->debug) {
        printf("ram[%04X] -> %02X\n", addr, val);
    }
    return val;
}

static inline void ram_set(struct RAM *self, u16 addr, u8 val) {
    if (self->debug) {
        printf("ram[%04X] <- %02X\n", addr, val);
    }
    switch (addr) {
        case 0x0000 ... 0x1FFF: {
            bool newval = (val != 0);
            // if(self->ram_enable != newval) printf("ram_enable set to %d\n", newval);
            self->ram_enable = newval;
            break;
        }
        case 0x2000 ... 0x3FFF: {
            self->rom_bank_low = val;
            self->rom_bank = (self->rom_bank_high << 5) | self->rom_bank_low;
            if (self->debug)
                printf("rom_bank set to %u/%u\n", self->rom_bank, self->cart->rom_size / ROM_BANK_SIZE);
            if (self->rom_bank * ROM_BANK_SIZE > self->cart->rom_size) {
                invalid_argument_err("Set rom_bank beyond the size of ROM");
            }
            break;
        }
        case 0x4000 ... 0x5FFF: {
            if (self->ram_bank_mode) {
                self->ram_bank = val;
                if (self->debug)
                    printf("ram_bank set to %u/%u\n", self->ram_bank, self->cart->ram_size / RAM_BANK_SIZE);
                if (self->ram_bank * RAM_BANK_SIZE > self->cart->ram_size) {
                    invalid_argument_err("Set ram_bank beyond the size of RAM");
                }
            } else {
                self->rom_bank_high = val;
                self->rom_bank = (self->rom_bank_high << 5) | self->rom_bank_low;
                if (self->debug)
                    printf("rom_bank set to %u/%u\n", self->rom_bank, self->cart->rom_size / ROM_BANK_SIZE);
                if (self->rom_bank * ROM_BANK_SIZE > self->cart->rom_size) {
                    invalid_argument_err("Set rom_bank beyond the size of ROM");
                }
            }
            break;
        }
        case 0x6000 ... 0x7FFF: {
            self->ram_bank_mode = (val != 0);
            // printf("ram_bank_mode set to %d\n", self->ram_bank_mode);
            break;
        }
        case 0x8000 ... 0x9FFF:
            // VRAM
            // TODO: if writing to tile RAM, update tiles in GPU class?
            break;
        case 0xA000 ... 0xBFFF: {
            // external RAM, bankable
            if (!self->ram_enable) {
                // printf("ERR: Writing to external ram while disabled: %04X=%02X\n", addr, val);
                return;
            }
            int bank = self->ram_bank * RAM_BANK_SIZE;
            int offset = addr - 0xA000;
            if (self->debug)
                printf("Writing external RAM: %04X=%02X (%02X:%04X)\n", bank + offset, val, self->ram_bank, offset);
            if (bank + offset >= self->cart->ram_size) {
                invalid_ram_write_err(self->ram_bank, offset, self->cart->ram_size);
            }
            self->cart->ram[bank + offset] = val;
            break;
        }
        case 0xC000 ... 0xCFFF:
            // work RAM, bank 0
            break;
        case 0xD000 ... 0xDFFF:
            // work RAM, bankable in CGB
            break;
        case 0xE000 ... 0xFDFF: {
            // ram[E000-FE00] mirrors ram[C000-DE00]
            self->data[addr - 0x2000] = val;
            break;
        }
        case 0xFE00 ... 0xFE9F:
            // Sprite attribute table
            break;
        case 0xFEA0 ... 0xFEFF:
            // Unusable
            // printf("Writing to invalid ram: %04X = %02X\n", addr, val);
            // throw std::invalid_argument("Writing to invalid RAM");
            break;
        case 0xFF00 ... 0xFF7F:
            // GPU Registers
            break;
        case 0xFF80 ... 0xFFFE:
            // High RAM
            break;
        case 0xFFFF:
            // IE Register
            break;
    }

    self->data[addr] = val;
}

#endif // ROSETTABOY_RAM_H
