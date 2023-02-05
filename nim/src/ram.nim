import std/strformat
import std/streams
import std/os
import std/bitops

import consts
import errors
import cart

const BOOT: array[0x100, int] = [
    # prod memory
    0x31, 0xFE, 0xFF, # LD SP,$FFFE
                      # enable LCD
    0x3E, 0x91,       # LD A,$91
    0xE0, 0x40,       # LDH [Mem::LCDC], A
                      # set flags
    0x3E, 0x01,       # LD A,$01
    0xCB, 0x7F,       # BIT 7,A (sets Z,n,H)
    0x37,             # SCF (sets C)
                      # set registers
    0x3E, 0x01,       # LD A,$01
    0x06, 0x00,       # LD B,$00
    0x0E, 0x13,       # LD C,$13
    0x16, 0x00,       # LD D,$00
    0x1E, 0xD8,       # LD E,$D8
    0x26, 0x01,       # LD H,$01
    0x2E, 0x4D,       # LD L,$4D
                      # skip to the end of the bootloader
    0xC3, 0xFD, 0x00, # JP $00FD
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
    # this instruction must be at the end of ROM --
    # after these finish executing, PC needs to be 0x100
    0xE0, 0x50, # LDH 50,A (disable boot rom)
]
const ROM_BANK_SIZE: uint16 = 0x4000
const RAM_BANK_SIZE: uint16 = 0x2000

type
    RAM* = ref object
        debug: bool
        cart: cart.Cart
        ramEnable: bool
        ramBankMode: bool
        romBankLow: uint8
        romBankHigh: uint8
        romBank: uint8
        ramBank: uint8
        boot: array[0x100, uint8]
        data*: array[0xFFFF+1, uint8]

proc create*(cart: Cart, debug: bool): RAM =
    var boot: array[0x100, uint8]
    try:
        if not fileExists("boot.gb"):
            raise newException(IOError, "no boot.gb")

        let stream = newFileStream("boot.gb")
        defer: stream.close()

        discard stream.readData(boot.addr, 0x100)
        boot[0xE9] = 0x00
        boot[0xEA] = 0x00
        boot[0xFA] = 0x00
        boot[0xFB] = 0x00
    except:
        # FIXME: can BOOT not just be an array of uint8??
        for i in 0..0xFF:
            boot[i] = BOOT[i].uint8

    return RAM(
      debug: debug,
      cart: cart,
      ramEnable: true,
      romBank_low: 1,
      romBank: 1,
      boot: boot,
    )

proc echoMem(address: uint16, val: uint8, right: bool) =
    let arrow = if right: "->" else: "<-"
    echo fmt"ram[{address:04X}] {arrow} {val:02X}"

template get*(self: RAM, address: uint16): uint8 =
    var val = self.data[address.int];
    case address:
        of 0x0000..0x3FFF:
            # ROM bank 0
            if self.data[consts.Mem_BOOT] == 0 and address < 0x0100:
                val = self.boot[cast[uint8](address)]
            else:
                val = self.cart.data[address].uint8

        of 0x4000..0x7FFF:
            # Switchable ROM bank
            # TODO: array bounds check
            let bank = self.romBank.int * ROM_BANK_SIZE.int
            let offset = address.int - 0x4000
            val = self.cart.data[offset + bank].uint8

        #of 0x8000..0x9FFF:
            # VRAM

        of 0xA000..0xBFFF:
            # 8KB Switchable RAM bank
            if not self.ramEnable:
                # panic!("Reading from external ram while disabled:::04X}", address);
                raise errors.InvalidRamRead.newException("FIXME ahrte")

            let bank = self.ramBank.int * RAM_BANK_SIZE.int;
            let offset = address.int - 0xA000;
            if bank + offset > self.cart.ram_size.int:
                # this should never happen because we die on ramBank being
                # set to a too-large value
                raise errors.InvalidRamRead.newException("FIXME brgbsd")
                #panic!(
                #    "Reading from external ram beyond limit:::04x} ({:02x}:{:04x})",
                #    bank + offset,
                #    self.ramBank,
                #    (address - 0xA000)
                #);

            val = self.cart.ram[bank + offset].uint8

        #of 0xC000..0xCFFF:
            # work RAM, bank 0

        #of 0xD000..0xDFFF:
            # work RAM, bankable in CGB

        of 0xE000..0xFDFF:
            # ram[E000-FE00] mirrors ram[C000-DE00]
            val = self.data[address.int - 0x2000];

        #of 0xFE00..0xFE9F:
            # Sprite attribute table

        of 0xFEA0..0xFEFF:
            # Unusable
            val = 0xFF;

        #of 0xFF00..0xFF7F:
            # IO Registers

        #of 0xFF80..0xFFFE:
            # High RAM

        #of 0xFFFF:
            # IE Register

        else:
            val = self.data[address.int];
    if self.debug:
        echoMem(address, val, false)
    val


template set*(self: RAM, address: uint16, val: uint8) =
    if self.debug:
        echoMem(address, val, true)

    case address:
        of 0x0000..0x1FFF:
            self.ramEnable = val != 0;

        of 0x2000..0x3FFF:
            self.romBank_low = val
            self.romBank = bitops.bitor((self.romBank_high shl 5), self.romBank_low)
            #tracing::debug!(
            #    "romBank set to:}/{}",
            #    self.romBank,
            #    self.cart.rom_size / ROM_BANK_SIZE as u32
            #);
            if self.romBank * ROM_BANK_SIZE > self.cart.rom_size:
                # panic!("Set romBank beyond the size of ROM");
                raise errors.InvalidRamWrite.newException("FIXME rom bank")


        of 0x4000..0x5FFF:
            if self.ramBank_mode:
                self.ramBank = val
                #tracing::debug!(
                #    "ramBank set to:}/{}",
                #    self.ramBank,
                #    self.cart.ram_size / RAM_BANK_SIZE as u32
                #);
                if self.ramBank * RAM_BANK_SIZE > self.cart.ram_size:
                    # panic!("Set ramBank beyond the size of RAM");
                    raise errors.InvalidRamWrite.newException("FIXME ram bank")

            else:
                self.romBank_high = val;
                self.romBank = bitops.bitor((self.romBank_high shl 5), self.romBank_low);
                #tracing::debug!(
                #    "romBank set to:}/{}",
                #    self.romBank,
                #    self.cart.rom_size / ROM_BANK_SIZE as u32
                #);
                if self.romBank * ROM_BANK_SIZE > self.cart.rom_size:
                    # panic!("Set romBank beyond the size of ROM");
                    raise errors.InvalidRamWrite.newException("FIXME rom bank")

        of 0x6000..0x7FFF:
            self.ramBank_mode = val != 0;
            # tracing::debug!("ramBank_mode set to:}", self.ramBank_mode);

        #of 0x8000..0x9FFF:
            # VRAM
            # TODO: if writing to tile RAM, update tiles in IO class?

        of 0xA000..0xBFFF:
            # external RAM, bankable
            if not self.ramEnable:
                raise errors.InvalidRamWrite.newException("FIXME hwthwt")
                #panic!(
                #    "Writing to external ram while disabled:::04x}={:02x}",
                #    address, val
                #);

            let bank = self.ramBank * RAM_BANK_SIZE
            let offset = address - 0xA000;
            #tracing::debug!(
            #    "Writing external RAM:::04x}={:02x} ({:02x}:{:04x})",
            #    bank + offset,
            #    val,
            #    self.ramBank,
            #    (address - 0xA000)
            #);
            if bank + offset >= self.cart.ram_size:
                #panic!("Writing beyond RAM limit");
                return;

            self.cart.ram[(bank + offset).int] = val.char

        #of 0xC000..0xCFFF:
            # work RAM, bank 0

        #of 0xD000..0xDFFF:
            # work RAM, bankable in CGB

        of 0xE000..0xFDFF:
            # ram[E000-FE00] mirrors ram[C000-DE00]
            self.data[address.int - 0x2000] = val;

        #of 0xFE00..0xFE9F:
            # Sprite attribute table

        #of 0xFEA0..0xFEFF:
            # Unusable
            # FIXME: tracing::debug!("Writing to invalid ram:::04x} =::02x}", address, val);

        #of 0xFF00..0xFF7F:
            # IO Registers
            #if address == Mem::SCX as uint16:
            #    println!("LY =:}, SCX =:}", self.get(Mem::LY), val);
            #}

        #of 0xFF80..0xFFFE:
            # High RAM

        #of 0xFFFF:
            # IE Register
        else:
            self.data[address.int] = val;
