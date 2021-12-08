<?php

define("ROM_BANK_SIZE", 0x4000);
define("RAM_BANK_SIZE", 0x2000);

class RAM
{
    public function __construct(Cart $cart, bool $debug)
    {
        $this->cart = $cart;
        $this->debug = $debug;
        if (is_readable("boot.gb")) {
            $boot = file_get_contents("boot.gb");
            // NOP the DRM
            $boot[0xE9] = 0x00;
            $boot[0xEA] = 0x00;
            $boot[0xFA] = 0x00;
            $boot[0xFB] = 0x00;
        } else {
            $boot = [
                // prod memory
                0x31, 0xFE, 0xFF, // LD SP,$FFFE

                // enable LCD
                0x3E, 0x91, // LD A,$91
                0xE0, 0x40, // LDH [Mem::LCDC], A

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
            ];
            for($i=count($boot); $i<0xFF; $i++) $boot[$i] = 0x00;
            // FIXME: pad to 0x100 bytes
            $boot[0xFE] = 0xE0; // LDH 50,A (disable boot rom)
            $boot[0xFF] = 0x50;
        }
        $this->boot = $boot;

        $this->data = array_fill(0, 0xFFFF+1, 0);
    }

    public function get(int $addr): int
    {
        if ($addr < 0x4000) {
            // ROM bank 0
            if ($this->data[Mem::$BOOT] == 0 && $addr < 0x0100) {
                return $this->boot[$addr];
            }
            return $this->cart->data[$addr];
        } elseif ($addr < 0x8000) {
            // Switchable ROM bank
            $bank = $this->rom_bank * ROM_BANK_SIZE;
            $offset = $addr - 0x4000;
            // printf("fetching %04X from bank %04X (total = %04X)\n", offset, bank, offset + bank);
            return $this->cart->data[$bank + $offset];
        } elseif ($addr < 0xA000) {
            // VRAM
        } elseif ($addr < 0xC000) {
            // 8KB Switchable RAM bank
            if (!$this->ram_enable) {
                printf("ERR: Reading from external ram while disabled: %04X\n", $addr);
                return 0;
            }
            $bank = $this->ram_bank * RAM_BANK_SIZE;
            $offset = $addr - 0xA000;
            return $this->cart->ram[$bank + $offset];
        } elseif ($addr < 0xD000) {
            // work RAM, bank 0
        } elseif ($addr < 0xE000) {
            // work RAM, bankable in CGB
        } elseif ($addr < 0xFE00) {
            // ram[E000-FE00] mirrors ram[C000-DE00]
            return $this->data[$addr - 0x2000];
        } elseif ($addr < 0xFEA0) {
            // Sprite attribute table
        } elseif ($addr < 0xFF00) {
            // Unusable
            return 0xFF;
        } elseif ($addr < 0xFF80) {
            // GPU Registers
        } elseif ($addr < 0xFFFF) {
            // High RAM
        } else {
            // IE Register
        }

        return $this->data[$addr];
    }

    public function set(int $addr, int $val): void
    {
        if ($addr < 0x2000) {
            $newval = ($val != 0);
            // if($this->ram_enable != newval) printf("ram_enable set to %d\n", newval);
            $this->ram_enable = $newval;
        } elseif ($addr < 0x4000) {
            $this->rom_bank_low = $val;
            $this->rom_bank = ($this->rom_bank_high << 5) | $this->rom_bank_low;
            if ($this->debug) {
                printf("rom_bank set to %u/%u\n", $this->rom_bank, $this->cart->rom_size / ROM_BANK_SIZE);
            }
            if ($this->rom_bank * ROM_BANK_SIZE > $this->cart->rom_size) {
                throw std::invalid_argument("Set rom_bank beyond the size of ROM");
            }
        } elseif ($addr < 0x6000) {
            if ($this->ram_bank_mode) {
                $this->ram_bank = $val;
                if ($this->debug) {
                    printf("ram_bank set to %u/%u\n", $this->ram_bank, $this->cart->ram_size / RAM_BANK_SIZE);
                }
                if ($this->ram_bank * RAM_BANK_SIZE > $this->cart->ram_size) {
                    throw std::invalid_argument("Set ram_bank beyond the size of RAM");
                }
            } else {
                $this->rom_bank_high = $val;
                $this->rom_bank = ($this->rom_bank_high << 5) | $this->rom_bank_low;
                if ($this->debug) {
                    printf("rom_bank set to %u/%u\n", $this->rom_bank, $this->cart->rom_size / ROM_BANK_SIZE);
                }
                if ($this->rom_bank * ROM_BANK_SIZE > $this->cart->rom_size) {
                    throw std::invalid_argument("Set rom_bank beyond the size of ROM");
                }
            }
        } elseif ($addr < 0x8000) {
            $this->ram_bank_mode = ($val != 0);
        // printf("ram_bank_mode set to %d\n", $this->ram_bank_mode);
        } elseif ($addr < 0xA000) {
            // VRAM
            // TODO: if writing to tile RAM, update tiles in GPU class?
        } elseif ($addr < 0xC000) {
            // external RAM, bankable
            if (!$this->ram_enable) {
                // printf("ERR: Writing to external ram while disabled: %04X=%02X\n", addr, val);
                return;
            }
            $bank = $this->ram_bank * RAM_BANK_SIZE;
            $offset = $addr - 0xA000;
            if ($this->debug) {
                printf(
                    "Writing external RAM: %04X=%02X (%02X:%04X)\n",
                    $bank + $offset,
                    $val,
                    $this->ram_bank,
                    ($addr - 0xA000)
                );
            }
            if ($bank + $offset > $this->cart->ram_size) {
                throw std::invalid_argument("Writing beyond RAM limit");
            }
            $this->cart->ram[$bank + $offset] = $val;
        } elseif ($addr < 0xD000) {
            // work RAM, bank 0
        } elseif ($addr < 0xE000) {
            // work RAM, bankable in CGB
        } elseif ($addr < 0xFE00) {
            // ram[E000-FE00] mirrors ram[C000-DE00]
            $this->data[$addr - 0x2000] = $val;
        } elseif ($addr < 0xFEA0) {
            // Sprite attribute table
        } elseif ($addr < 0xFF00) {
            // Unusable
            // printf("Writing to invalid ram: %04X = %02X\n", addr, val);
            // throw std::invalid_argument("Writing to invalid RAM");
        } elseif ($addr < 0xFF80) {
            // GPU Registers
        } elseif ($addr < 0xFFFF) {
            // High RAM
        } else {
            // IE Register
        }

        $this->data[$addr] = $val;
    }

    function _and($addr, $val) { $this->set($addr, $this->get($addr) & $val); }
    function _or($addr, $val) { $this->set($addr, $this->get($addr) | $val); }
    function _inc($addr) { $this->set($addr, $this->get($addr) + 1); }
}
