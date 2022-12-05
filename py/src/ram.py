import typing as t
from .cart import Cart
from .consts import Mem, u16, u8

ROM_BANK_SIZE: t.Final[u16] = 0x4000
RAM_BANK_SIZE: t.Final[u16] = 0x2000


class RAM:
    def __init__(self, cart: Cart, debug: bool = False) -> None:
        self.cart = cart
        self.boot = self.get_boot()
        self.data = [0] * (0xFFFF + 1)
        self.debug = debug

        self.ram_enable = True
        self.ram_bank_mode = False
        self.rom_bank_low = 1
        self.rom_bank_high = 0
        self.rom_bank = 1
        self.ram_bank = 0

    def get_boot(self) -> t.List[int]:
        try:
            # boot with the logo scroll if we have a boot rom
            with open("boot.gb", "rb") as fp:
                BOOT = list(fp.read(0x100))
                # NOP the DRM
                BOOT[0xE9] = 0x00
                BOOT[0xEA] = 0x00
                BOOT[0xFA] = 0x00
                BOOT[0xFB] = 0x00
        except IOError:
            # fmt: off
            # Directly set CPU registers as
            # if the logo had been scrolled
            BOOT = [
                # prod memory
                0x31, 0xFE, 0xFF,  # LD SP,$FFFE

                # enable LCD
                0x3E, 0x91, # LD A,$91
                0xE0, 0x40, # LDH [Mem.:LCDC], A

                # set flags
                0x3E, 0x01,  # LD A,$00
                0xCB, 0x7F,  # BIT 7,A (sets Z,n,H)
                0x37,        # SCF (sets C)

                # set registers
                0x3E, 0x01,  # LD A,$01
                0x06, 0x00,  # LD B,$00
                0x0E, 0x13,  # LD C,$13
                0x16, 0x00,  # LD D,$00
                0x1E, 0xD8,  # LD E,$D8
                0x26, 0x01,  # LD H,$01
                0x2E, 0x4D,  # LD L,$4D

                # skip to the end of the bootloader
                0xC3, 0xFD, 0x00,  # JP 0x00FD
            ]
            # fmt: on

            # these 5 instructions must be the final 2 --
            # after these finish executing, PC needs to be 0x100
            BOOT += [0x00] * (0xFE - len(BOOT))
            BOOT += [0xE0, 0x50]  # LDH 50,A (disable boot rom)

        assert len(BOOT) == 0x100, f"Bootloader must be 256 bytes ({len(BOOT)})"
        return BOOT

    def __getitem__(self, addr: u16) -> u8:
        val = self.data[addr]
        if addr < 0x4000:
            # ROM bank 0
            if self.data[Mem.BOOT] == 0 and addr < 0x100:
                val = self.boot[addr]
            else:
                val = self.cart.data[addr]
        elif addr < 0x8000:
            # Switchable ROM bank
            # TODO: array bounds check
            offset = addr - 0x4000
            bank = self.rom_bank * ROM_BANK_SIZE
            val = self.cart.data[bank + offset]
        elif addr < 0xA000:
            # VRAM
            pass
        elif addr < 0xC000:
            # 8KB Switchable RAM bank
            if not self.ram_enable:
                raise Exception(
                    "Reading from external ram while disabled: {:04X}", addr
                )
            bank = self.ram_bank * RAM_BANK_SIZE
            offset = addr - 0xA000
            if bank + offset >= self.cart.ram_size:
                # this should never happen because we die on ram_bank being
                # set to a too-large value
                raise Exception(
                    "Reading from external ram beyond limit: {:04x} ({:02x}:{:04x})",
                    bank + offset,
                    self.ram_bank,
                    offset,
                )
            val = self.cart.ram[bank + offset]
        elif addr < 0xD000:
            # work RAM, bank 0
            pass
        elif addr < 0xE000:
            # work RAM, bankable in CGB
            pass
        elif addr < 0xFE00:
            # ram[E000-FE00] mirrors ram[C000-DE00]
            val = self.data[addr - 0x2000]
        elif addr < 0xFEA0:
            # Sprite attribute table
            pass
        elif addr < 0xFF00:
            # Unusable
            val = 0xFF
        elif addr < 0xFF80:
            # IO Registers
            pass
        elif addr < 0xFFFF:
            # High RAM
            pass
        else:
            # IE Register
            pass

        if self.debug:
            print(f"ram[{addr:04X}] -> {val:02X}")
        return val

    def __setitem__(self, addr: u16, val: u8) -> None:
        if self.debug:
            print(f"ram[{addr:04X}] <- {val:02X}")
        if addr < 0x2000:
            self.ram_enable = val != 0
        elif addr < 0x4000:
            self.rom_bank_low = val
            self.rom_bank = (self.rom_bank_high << 5) | self.rom_bank_low
            if self.debug:
                print(
                    "rom_bank set to {}/{}",
                    self.rom_bank,
                    self.cart.rom_size / ROM_BANK_SIZE,
                )
            if self.rom_bank * ROM_BANK_SIZE > self.cart.rom_size:
                raise Exception("Set rom_bank beyond the size of ROM")
        elif addr < 0x6000:
            if self.ram_bank_mode:
                self.ram_bank = val
                if self.debug:
                    print(
                        "ram_bank set to {}/{}",
                        self.ram_bank,
                        self.cart.ram_size / RAM_BANK_SIZE,
                    )
                if self.ram_bank * RAM_BANK_SIZE > self.cart.ram_size:
                    raise Exception("Set ram_bank beyond the size of RAM")
            else:
                self.rom_bank_high = val
                self.rom_bank = (self.rom_bank_high << 5) | self.rom_bank_low
                if self.debug:
                    print(
                        "rom_bank set to {}/{}",
                        self.rom_bank,
                        self.cart.rom_size / ROM_BANK_SIZE,
                    )
                if self.rom_bank * ROM_BANK_SIZE > self.cart.rom_size:
                    raise Exception("Set rom_bank beyond the size of ROM")
        elif addr < 0x8000:
            self.ram_bank_mode = val != 0
            if self.debug:
                print("ram_bank_mode set to {}", self.ram_bank_mode)
        elif addr < 0xA000:
            # VRAM
            # TODO: if writing to tile RAM, update tiles in Mem.class?
            pass
        elif addr < 0xC000:
            # external RAM, bankable
            if not self.ram_enable:
                raise Exception(
                    "Writing to external ram while disabled: {:04x}={:02x}", addr, val
                )
            bank = self.ram_bank * RAM_BANK_SIZE
            offset = addr - 0xA000
            if self.debug:
                print(
                    "Writing external RAM: {:04x}={:02x} ({:02x}:{:04x})",
                    bank + offset,
                    val,
                    self.ram_bank,
                    offset,
                )
            if bank + offset >= self.cart.ram_size:
                raise Exception(
                    "Writing to external ram beyond limit: {:04x} ({:02x}:{:04x})",
                    bank + offset,
                    self.ram_bank,
                    offset,
                )
            self.cart.ram[bank + offset] = val
        elif addr < 0xD000:
            # work RAM, bank 0
            pass
        elif addr < 0xE000:
            # work RAM, bankable in CGB
            pass
        elif addr < 0xFE00:
            # ram[E000-FE00] mirrors ram[C000-DE00]
            self.data[addr - 0x2000] = val
        elif addr < 0xFEA0:
            # Sprite attribute table
            pass
        elif addr < 0xFF00:
            # Unusable
            if self.debug:
                print("Writing to invalid ram: {:04x} = {:02x}", addr, val)
        elif addr < 0xFF80:
            # IO Registers
            # if addr == Mem.:SCX as u16 {
            #     println!("LY = {}, SCX = {}", self.get(Mem.:LY), val);
            # }
            pass
        elif addr < 0xFFFF:
            # High RAM
            pass
        else:
            # IE Register
            pass

        self.data[addr] = val
