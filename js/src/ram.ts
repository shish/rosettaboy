import { Cart } from "./cart";
import { Mem } from "./consts";
import { InvalidRamRead, InvalidRamWrite } from "./errors";
import { hex } from "./_utils";

/**
 * A minimal boot ROM which just sets values the same as
 * the canonical ROM and then gets out of the way - no
 * logo scrolling or DRM.
 */
// prettier-ignore
const BOOT: Uint8Array = new Uint8Array([
    // prod memory
    0x31, 0xFE, 0xFF, // LD SP,$FFFE
    // enable LCD
    0x3E, 0x91, // LD A,$91
    0xE0, 0x40, // LDH [Mem::LCDC], A
    // set flags
    0x3E, 0x01, // LD A,$01
    0xCB, 0x7F, // BIT 7,A (sets Z,n,H)
    0x37, // SCF (sets C)
    // set registers
    0x3E, 0x01, // LD A,$01
    0x06, 0x00, // LD B,$00
    0x0E, 0x13, // LD C,$13
    0x16, 0x00, // LD D,$00
    0x1E, 0xD8, // LD E,$D8
    0x26, 0x01, // LD H,$01
    0x2E, 0x4D, // LD L,$4D
    // skip to the end of the bootloader
    0xC3, 0xFD, 0x00, // JP $00FD
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00,
    // this instruction must be at the end of ROM --
    // after these finish executing, PC needs to be 0x100
    0xE0, 0x50, // LDH 50,A (disable boot rom)
]);
const ROM_BANK_SIZE: number = 0x4000;
const RAM_BANK_SIZE: number = 0x2000;

export class RAM {
    cart: Cart;
    debug: boolean;

    ram_enable: boolean;
    ram_bank_mode: boolean;
    rom_bank_low: number;
    rom_bank_high: number;
    rom_bank: number;
    ram_bank: number;
    boot: Uint8Array;
    data: Uint8Array;

    constructor(cart: Cart, debug: boolean) {
        this.cart = cart;
        this.debug = debug;

        this.ram_enable = false;
        this.ram_bank_mode = false;
        this.rom_bank_low = 1;
        this.rom_bank_high = 0;
        this.rom_bank = 1;
        this.ram_bank = 0;
        this.boot = BOOT;
        // FIXME: try loading boot.gb
        this.data = new Uint8Array(0x10000);
    }

    get(addr: number): number {
        let val = this.data[addr];
        if (addr < 0x4000) {
            // ROM bank 0
            if (this.data[Mem.BOOT] == 0 && addr < 0x100) val = this.boot[addr];
            else val = this.cart.data[addr];
        } else if (addr < 0x8000) {
            // Switchable ROM bank
            // TODO: array bounds check
            const offset = addr - 0x4000;
            const bank = this.rom_bank * ROM_BANK_SIZE;
            //console.log(this.rom_bank, bank, offset, this.cart.data[bank + offset]);
            val = this.cart.data[bank + offset];
        } else if (addr < 0xa000) {
            // VRAM
        } else if (addr < 0xc000) {
            // 8KB Switchable RAM bank
            if (!this.ram_enable)
                throw new InvalidRamRead(
                    `Reading from external ram while disabled: ${hex(addr, 4)}`,
                );
            const bank = this.ram_bank * RAM_BANK_SIZE;
            const offset = addr - 0xa000;
            if (bank + offset >= this.cart.ram_size) {
                // this should never happen because we die on ram_bank being
                // set to a too-large value
                throw new InvalidRamRead(
                    `Reading from external ram beyond limit: ${hex(
                        bank + offset,
                        4,
                    )} (${hex(this.ram_bank, 2)}:${hex(offset, 4)})`,
                );
            }
            val = this.cart.ram[bank + offset];
        } else if (addr < 0xd000) {
            // work RAM, bank 0
        } else if (addr < 0xe000) {
            // work RAM, bankable in CGB
        } else if (addr < 0xfe00) {
            // ram[E000-FE00] mirrors ram[C000-DE00]
            val = this.data[addr - 0x2000];
        } else if (addr < 0xfea0) {
            // Sprite attribute table
        } else if (addr < 0xff00) {
            // Unusable
            val = 0xff;
        } else if (addr < 0xff80) {
            // IO Registers
        } else if (addr < 0xffff) {
            // High RAM
        } else {
            // IE Register
        }

        if (this.debug) {
            console.log(`ram[${hex(addr, 4)}] -> ${hex(val, 2)}`);
        }
        return val;
    }

    set(addr: number, val: number) {
        if (this.debug) {
            console.log(`ram[${hex(addr, 4)}] <- ${hex(val, 2)}`);
        }
        if (val < 0 || val > 0xff || val != Math.floor(val)) {
            throw new Error("Invalid ram write");
        }
        if (addr < 0x2000) {
            this.ram_enable = val != 0;
        } else if (addr < 0x4000) {
            this.rom_bank_low = val;
            this.rom_bank = (this.rom_bank_high << 5) | this.rom_bank_low;
            if (this.debug) {
                console.log(
                    "rom_bank set to {}/{}",
                    this.rom_bank,
                    this.cart.rom_size / ROM_BANK_SIZE,
                );
            }
            if (this.rom_bank * ROM_BANK_SIZE > this.cart.rom_size) {
                throw new InvalidRamWrite(
                    "Set rom_bank beyond the size of ROM",
                );
            }
        } else if (addr < 0x6000) {
            if (this.ram_bank_mode) {
                this.ram_bank = val;
                if (this.debug) {
                    console.log(
                        "ram_bank set to {}/{}",
                        this.ram_bank,
                        this.cart.ram_size / RAM_BANK_SIZE,
                    );
                }
                if (this.ram_bank * RAM_BANK_SIZE > this.cart.ram_size) {
                    throw new InvalidRamWrite(
                        "Set ram_bank beyond the size of RAM",
                    );
                }
            } else {
                this.rom_bank_high = val;
                this.rom_bank = (this.rom_bank_high << 5) | this.rom_bank_low;
                if (this.debug) {
                    console.log(
                        "rom_bank set to {}/{}",
                        this.rom_bank,
                        this.cart.rom_size / ROM_BANK_SIZE,
                    );
                }
                if (this.rom_bank * ROM_BANK_SIZE > this.cart.rom_size) {
                    throw new InvalidRamWrite(
                        "Set rom_bank beyond the size of ROM",
                    );
                }
            }
        } else if (addr < 0x8000) {
            this.ram_bank_mode = val != 0;
            if (this.debug) {
                console.log("ram_bank_mode set to {}", this.ram_bank_mode);
            }
        } else if (addr < 0xa000) {
            // VRAM
            // TODO: if(writing to tile RAM, update tiles in Mem.class?
        } else if (addr < 0xc000) {
            // external RAM, bankable
            if (!this.ram_enable) {
                throw new InvalidRamWrite(
                    `Writing to external ram while disabled: ${hex(
                        addr,
                        4,
                    )}=${hex(val, 2)}`,
                );
            }
            const bank = this.ram_bank * RAM_BANK_SIZE;
            const offset = addr - 0xa000;
            if (this.debug) {
                console.log(
                    `Writing external RAM: ${hex(bank + offset, 4)}=${hex(
                        val,
                        2,
                    )} (${hex(this.ram_bank, 2)}:${hex(offset, 4)})`,
                );
            }
            if (bank + offset >= this.cart.ram_size) {
                throw new InvalidRamWrite(
                    `Writing to external ram beyond limit: ${hex(
                        bank + offset,
                        4,
                    )} (${hex(this.ram_bank, 2)}:${hex(offset, 4)})`,
                );
            }
            this.cart.ram[bank + offset] = val;
        } else if (addr < 0xd000) {
            // work RAM, bank 0
        } else if (addr < 0xe000) {
            // work RAM, bankable in CGB
        } else if (addr < 0xfe00) {
            // ram[E000-FE00] mirrors ram[C000-DE00]
            this.data[addr - 0x2000] = val;
        } else if (addr < 0xfea0) {
            // Sprite attribute table
        } else if (addr < 0xff00) {
            // Unusable
            if (this.debug) {
                console.log(
                    "Writing to invalid ram: {:04x} = {:02x}",
                    addr,
                    val,
                );
            }
        } else if (addr < 0xff80) {
            // IO Registers
            // if(addr == Mem.:SCX as u16 {
            //     console.logln!("LY = {}, SCX = {}", this.get(Mem.:LY), val);
            // }
        } else if (addr < 0xffff) {
            // High RAM
        } else {
            // IE Register
        }

        this.data[addr] = val;
    }
}
