from .cart import Cart
from .consts import *


class RAM:
    def __init__(self, cart: Cart, debug: bool = False):
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

        # 16KB ROM bank 0
        for x in range(0x0000, 0x4000):
            self.data[x] = self.cart.data[x]

        # 16KB Switchable ROM bank
        for x in range(0x4000, 0x8000):
            self.data[x] = self.cart.data[x]

        # 8KB VRAM
        # 0x8000 - 0xA000
        # from random import randint
        # for x in range(0x8000, 0xA000):
        #   self.data[x] = randint(0, 256)

        # 8KB Switchable RAM bank
        # 0xA000 - 0xC000

        # 8KB Internal RAM
        # 0xC000 - 0xE000

        # Echo internal RAM
        # 0xE000 - 0xFE00

        # Sprite Attrib Memory (OAM)
        # 0xFE00 - 0xFEA0

        # Empty
        # 0xFEA0 - 0xFF00

        # IO Ports
        # 0xFF00 - 0xFF4C
        self.data[0xFF00] = 0x00  # BUTTONS

        self.data[0xFF01] = 0x00  # SB (Serial Data)
        self.data[0xFF02] = 0x00  # SC (Serial Control)

        self.data[0xFF04] = 0x00  # DIV
        self.data[0xFF05] = 0x00  # TIMA
        self.data[0xFF06] = 0x00  # TMA
        self.data[0xFF07] = 0x00  # TAC

        self.data[0xFF0F] = 0x00  # IF

        self.data[0xFF10] = 0x80  # NR10
        self.data[0xFF11] = 0xBF  # NR11
        self.data[0xFF12] = 0xF3  # NR12
        self.data[0xFF14] = 0xBF  # NR14
        self.data[0xFF16] = 0x3F  # NR21
        self.data[0xFF17] = 0x00  # NR22
        self.data[0xFF19] = 0xBF  # NR24
        self.data[0xFF1A] = 0x7F  # NR30
        self.data[0xFF1B] = 0xFF  # NR31
        self.data[0xFF1C] = 0x9F  # NR32
        self.data[0xFF1E] = 0xBF  # NR33
        self.data[0xFF20] = 0xFF  # NR41
        self.data[0xFF21] = 0x00  # NR42
        self.data[0xFF22] = 0x00  # NR43
        self.data[0xFF23] = 0xBF  # NR30
        self.data[0xFF24] = 0x77  # NR50
        self.data[0xFF25] = 0xF3  # NR51
        self.data[0xFF26] = 0xF1  # NR52  # 0xF0 on SGB

        self.data[0xFF40] = 0x00  # LCDC - official boot rom inits this to 0x91
        self.data[0xFF41] = 0x00  # STAT
        self.data[0xFF42] = 0x00  # SCX aka SCROLL_Y
        self.data[0xFF43] = 0x00  # SCY aka SCROLL_X
        self.data[0xFF44] = 144  # LY aka currently drawn line, 0-153, >144 = vblank
        self.data[0xFF45] = 0x00  # LYC
        self.data[0xFF46] = 0x00  # DMA
        self.data[0xFF47] = 0xFC  # BGP
        self.data[0xFF48] = 0xFF  # OBP0
        self.data[0xFF49] = 0xFF  # OBP1
        self.data[0xFF4A] = 0x00  # WY
        self.data[0xFF4B] = 0x00  # WX

        # Empty
        # 0xFF4C - 0xFF80

        # Internal RAM
        # 0xFF80 - 0xFFFF

        # Interrupt Enabled Register
        self.data[0xFFFF] = 0x00  # IE

        # TODO: ram[E000-FE00] mirrors ram[C000-DE00]

    def get_boot(self):
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
                0xE0, 0x40, # LDH [IO::LCDC], A

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

    def __getitem__(self, addr):
        if addr < 0x4000:
            # ROM bank 0
            if self.data[IO_BOOT] == 0 and addr < 0x100:
                return self.boot[addr]
            return self.data[addr]
        elif addr < 0x8000:
            # Switchable ROM bank
            # TODO: array bounds check
            offset = addr - 0x4000
            bank = 0x4000 * self.rom_bank
            if self.debug:
                print(
                    "fetching {:04x} from bank {:04x} (total = {:04x})",
                    offset,
                    bank,
                    offset + bank,
                )
            return self.cart.data[bank + offset]
        elif addr < 0xA000:
            # VRAM
            pass
        elif addr < 0xC000:
            # 8KB Switchable RAM bank
            if not self.ram_enable:
                raise Exception(
                    "Reading from external ram while disabled: {:04X}", addr
                )
            addr_within_ram = (self.ram_bank * 0x2000) + (addr - 0xA000)
            if addr_within_ram > self.cart.ram_size:
                # this should never happen because we die on ram_bank being
                # set to a too-large value
                raise Exception(
                    "Reading from external ram beyond limit: {:04x} ({:02x}:{:04x})",
                    addr_within_ram,
                    self.ram_bank,
                    (addr - 0xA000),
                )
            return self.cart.ram[addr_within_ram]
        elif addr < 0xD000:
            # work RAM, bank 0
            pass
        elif addr < 0xE000:
            # work RAM, bankable in CGB
            pass
        elif addr < 0xFE00:
            # ram[E000-FE00] mirrors ram[C000-DE00]
            return self.data[addr - 0x2000]
        elif addr < 0xFEA0:
            # Sprite attribute table
            pass
        elif addr < 0xFF00:
            # Unusable
            return 0xFF
        elif addr < 0xFF80:
            # IO Registers
            pass
        elif addr < 0xFFFF:
            # High RAM
            pass
        else:
            # IE Register
            pass

        return self.data[addr]

    def __setitem__(self, addr, val):
        if addr < 0x2000:
            self.ram_enable = val != 0
        elif addr < 0x4000:
            self.rom_bank_low = val
            self.rom_bank = (self.rom_bank_high << 5) | self.rom_bank_low
            if self.debug:
                print(
                    "rom_bank set to {}/{}", self.rom_bank, self.cart.rom_size / 0x2000
                )
            if self.rom_bank * 0x2000 > self.cart.rom_size:
                raise Exception("Set rom_bank beyond the size of ROM")
        elif addr < 0x6000:
            if self.ram_bank_mode:
                self.ram_bank = val
                if self.debug:
                    print(
                        "ram_bank set to {}/{}",
                        self.ram_bank,
                        self.cart.ram_size / 0x2000,
                    )
                if self.ram_bank * 0x2000 > self.cart.ram_size:
                    raise Exception("Set ram_bank beyond the size of RAM")
            else:
                self.rom_bank_high = val
                self.rom_bank = (self.rom_bank_high << 5) | self.rom_bank_low
                if self.debug:
                    print(
                        "rom_bank set to {}/{}",
                        self.rom_bank,
                        self.cart.rom_size / 0x2000,
                    )
                if self.rom_bank * 0x2000 > self.cart.rom_size:
                    raise Exception("Set rom_bank beyond the size of ROM")
        elif addr < 0x8000:
            self.ram_bank_mode = val != 0
            if self.debug:
                print("ram_bank_mode set to {}", self.ram_bank_mode)
        elif addr < 0xA000:
            # VRAM
            # TODO: if writing to tile RAM, update tiles in IO class?
            pass
        elif addr < 0xC000:
            # external RAM, bankable
            if not self.ram_enable:
                raise Exception(
                    "Writing to external ram while disabled: {:04x}={:02x}", addr, val
                )
            addr_within_ram = (self.ram_bank * 0x2000) + (addr - 0xA000)
            if self.debug:
                print(
                    "Writing external RAM: {:04x}={:02x} ({:02x}:{:04x})",
                    addr_within_ram,
                    val,
                    self.ram_bank,
                    (addr - 0xA000),
                )
            if addr_within_ram >= self.cart.ram_size:
                # raise Exception!("Writing beyond RAM limit")
                return
            self.cart.ram[addr_within_ram] = val
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
            # if addr == IO::SCX as u16 {
            #     println!("LY = {}, SCX = {}", self.get(IO::LY), val);
            # }
            pass
        elif addr < 0xFFFF:
            # High RAM
            pass
        else:
            # IE Register
            pass

        self.data[addr] = val
