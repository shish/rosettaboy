#ifndef ROSETTABOY_RAM_H
#define ROSETTABOY_RAM_H

#include <stdexcept>

#include "cart.h"
#include "consts.h"
#include "errors.h"

const u16 ROM_BANK_SIZE = 0x4000;
const u16 RAM_BANK_SIZE = 0x2000;

class RAM {
private:
    Cart *cart;
    bool ram_enable = false;
    bool ram_bank_mode = false;
    u8 rom_bank_low = 1;
    u8 rom_bank_high = 0;
    u8 rom_bank = 1;
    u8 ram_bank = 0;
    u8 *boot;
    bool debug = false;

public:
    RAM(Cart *cart, bool debug);
    u8 data[0xFFFF + 1];
    void dump();

    /**
     * Inline these in the header because many calls
     * can be optimised into a single instruction
     */
public:
    inline u8 get(u16 addr);
    inline void set(u16 addr, u8 val);
};

inline u8 RAM::get(u16 addr) {
    u8 val = this->data[addr];
    switch(addr) {
        case 0x0000 ... 0x3FFF: {
            // ROM bank 0
            if(this->data[Mem::BOOT] == 0 && addr < 0x0100) {
                val = this->boot[addr];
            } else {
                val = this->cart->data[addr];
            }
            break;
        }
        case 0x4000 ... 0x7FFF: {
            // Switchable ROM bank
            int bank = this->rom_bank * ROM_BANK_SIZE;
            int offset = addr - 0x4000;
            // printf("fetching %04X from bank %04X (total = %04X)\n", offset, bank, offset + bank);
            val = this->cart->data[bank + offset];
            break;
        }
        case 0x8000 ... 0x9FFF:
            // VRAM
            break;
        case 0xA000 ... 0xBFFF: {
            // 8KB Switchable RAM bank
            if(!this->ram_enable) {
                printf("ERR: Reading from external ram while disabled: %04X\n", addr);
                return 0;
            }
            int bank = this->ram_bank * RAM_BANK_SIZE;
            int offset = addr - 0xA000;
            if(bank + offset >= this->cart->ram_size) {
                throw new InvalidRamRead(this->ram_bank, offset, this->cart->ram_size);
            }
            val = this->cart->ram[bank + offset];
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
            val = this->data[addr - 0x2000];
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

    if(this->debug) {
        printf("ram[%04X] -> %02X\n", addr, val);
    }
    return val;
}

inline void RAM::set(u16 addr, u8 val) {
    if(this->debug) {
        printf("ram[%04X] <- %02X\n", addr, val);
    }
    switch(addr) {
        case 0x0000 ... 0x1FFF: {
            bool newval = (val != 0);
            // if(this->ram_enable != newval) printf("ram_enable set to %d\n", newval);
            this->ram_enable = newval;
            break;
        }
        case 0x2000 ... 0x3FFF: {
            this->rom_bank_low = val;
            this->rom_bank = (this->rom_bank_high << 5) | this->rom_bank_low;
            if(this->debug) printf("rom_bank set to %u/%u\n", this->rom_bank, this->cart->rom_size / ROM_BANK_SIZE);
            if(this->rom_bank * ROM_BANK_SIZE > this->cart->rom_size) {
                throw std::invalid_argument("Set rom_bank beyond the size of ROM");
            }
            break;
        }
        case 0x4000 ... 0x5FFF: {
            if(this->ram_bank_mode) {
                this->ram_bank = val;
                if(this->debug) printf("ram_bank set to %u/%u\n", this->ram_bank, this->cart->ram_size / RAM_BANK_SIZE);
                if(this->ram_bank * RAM_BANK_SIZE > this->cart->ram_size) {
                    throw std::invalid_argument("Set ram_bank beyond the size of RAM");
                }
            } else {
                this->rom_bank_high = val;
                this->rom_bank = (this->rom_bank_high << 5) | this->rom_bank_low;
                if(this->debug) printf("rom_bank set to %u/%u\n", this->rom_bank, this->cart->rom_size / ROM_BANK_SIZE);
                if(this->rom_bank * ROM_BANK_SIZE > this->cart->rom_size) {
                    throw std::invalid_argument("Set rom_bank beyond the size of ROM");
                }
            }
            break;
        }
        case 0x6000 ... 0x7FFF: {
            this->ram_bank_mode = (val != 0);
            // printf("ram_bank_mode set to %d\n", this->ram_bank_mode);
            break;
        }
        case 0x8000 ... 0x9FFF:
            // VRAM
            // TODO: if writing to tile RAM, update tiles in GPU class?
            break;
        case 0xA000 ... 0xBFFF: {
            // external RAM, bankable
            if(!this->ram_enable) {
                // printf("ERR: Writing to external ram while disabled: %04X=%02X\n", addr, val);
                return;
            }
            int bank = this->ram_bank * RAM_BANK_SIZE;
            int offset = addr - 0xA000;
            if(this->debug)
                printf("Writing external RAM: %04X=%02X (%02X:%04X)\n", bank + offset, val, this->ram_bank, offset);
            if(bank + offset >= this->cart->ram_size) {
                throw new InvalidRamWrite(this->ram_bank, offset, this->cart->ram_size);
            }
            this->cart->ram[bank + offset] = val;
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
            this->data[addr - 0x2000] = val;
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

    this->data[addr] = val;
}

#endif // ROSETTABOY_RAM_H
