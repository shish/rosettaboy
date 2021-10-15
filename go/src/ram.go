package main

import (
	"io/ioutil"
)

type RAM struct {
	cart  *Cart
	boot  []byte
	data  []byte
	debug bool

	ram_enable    bool
	ram_bank_mode bool
	rom_bank_low  uint8
	rom_bank_high uint8
	rom_bank      uint8
	ram_bank      uint8
}

func NewRAM(cart *Cart, debug bool) RAM {
	var boot = get_boot()
	var data = make([]byte, 64*1024)

	// 16KB ROM bank 0
	for x := 0x0000; x < 0x4000; x++ {
		data[x] = cart.data[x]
	}

	// 16KB Switchable ROM bank
	for x := 0x4000; x < 0x8000; x++ {
		data[x] = cart.data[x]
	}

	// 8KB VRAM
	// 0x8000 - 0xA000
	// from random import randint
	// for x in range(0x8000, 0xA000):
	//   data[x] = randint(0, 256)

	// 8KB Switchable RAM bank
	// 0xA000 - 0xC000

	// 8KB Internal RAM
	// 0xC000 - 0xE000

	// Echo internal RAM
	// 0xE000 - 0xFE00

	// Sprite Attrib Memory (OAM)
	// 0xFE00 - 0xFEA0

	// Empty
	// 0xFEA0 - 0xFF00

	// IO Ports
	// 0xFF00 - 0xFF4C
	data[0xFF00] = 0x00 // BUTTONS

	data[0xFF01] = 0x00 // SB (Serial Data)
	data[0xFF02] = 0x00 // SC (Serial Control)

	data[0xFF04] = 0x00 // DIV
	data[0xFF05] = 0x00 // TIMA
	data[0xFF06] = 0x00 // TMA
	data[0xFF07] = 0x00 // TAC

	data[0xFF0F] = 0x00 // IF

	data[0xFF10] = 0x80 // NR10
	data[0xFF11] = 0xBF // NR11
	data[0xFF12] = 0xF3 // NR12
	data[0xFF14] = 0xBF // NR14
	data[0xFF16] = 0x3F // NR21
	data[0xFF17] = 0x00 // NR22
	data[0xFF19] = 0xBF // NR24
	data[0xFF1A] = 0x7F // NR30
	data[0xFF1B] = 0xFF // NR31
	data[0xFF1C] = 0x9F // NR32
	data[0xFF1E] = 0xBF // NR33
	data[0xFF20] = 0xFF // NR41
	data[0xFF21] = 0x00 // NR42
	data[0xFF22] = 0x00 // NR43
	data[0xFF23] = 0xBF // NR30
	data[0xFF24] = 0x77 // NR50
	data[0xFF25] = 0xF3 // NR51
	data[0xFF26] = 0xF1 // NR52  // 0xF0 on SGB

	data[0xFF40] = 0x00 // LCDC - official boot rom inits this to 0x91
	data[0xFF41] = 0x00 // STAT
	data[0xFF42] = 0x00 // SCX aka SCROLL_Y
	data[0xFF43] = 0x00 // SCY aka SCROLL_X
	data[0xFF44] = 144  // LY aka currently drawn line, 0-153, >144 = vblank
	data[0xFF45] = 0x00 // LYC
	data[0xFF46] = 0x00 // DMA
	data[0xFF47] = 0xFC // BGP
	data[0xFF48] = 0xFF // OBP0
	data[0xFF49] = 0xFF // OBP1
	data[0xFF4A] = 0x00 // WY
	data[0xFF4B] = 0x00 // WX

	// Empty
	// 0xFF4C - 0xFF80

	// Internal RAM
	// 0xFF80 - 0xFFFF

	// Interrupt Enabled Register
	data[0xFFFF] = 0x00 // IE

	// TODO: ram[E000-FE00] mirrors ram[C000-DE00]

	return RAM{
		cart, boot, data, debug, true, false, 1, 0, 1, 0,
	}
}

func get_boot() []byte {
	var data, err = ioutil.ReadFile("boot.gb")
	if err == nil {
		// NOP the DRM
		data[0xE9] = 0x00
		data[0xEA] = 0x00
		data[0xFA] = 0x00
		data[0xFB] = 0x00
	} else {
		// Directly set CPU registers as
		// if the logo had been scrolled
		data = []byte{
			// prod memory
			0x31, 0xFE, 0xFF, // LD SP,$FFFE

			// enable LCD
			0x3E, 0x91, // LD A,$91
			0xE0, 0x40, // LDH [IO::LCDC], A

			// set flags
			0x3E, 0x01, // LD A,$00
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
			0xC3, 0xFD, 0x00, // JP 0x00FD
		}

		// these 5 instructions must be the final 2 --
		// after these finish executing, PC needs to be 0x100
		data = append(data, make([]byte, 0xFE-len(data))...) // null padding
		data = append(data, []byte{0xE0, 0x50}...)           // LDH 50,A (disable boot rom)
	}

	if len(data) != 0x100 {
		panic("Bootloader must be 256 bytes ({len(BOOT)})") // FIXME
	}
	return data
}

func (self *RAM) get(addr uint16) uint8 {
	switch {
	case addr < 0x4000:
		// ROM bank 0
		if self.data[IO_BOOT] == 0 && addr < 0x100 {
			return self.boot[addr]
		}
		return self.data[addr]
	case addr < 0x8000:
		// Switchable ROM bank
		// TODO: array bounds check
		var offset = addr - 0x4000
		var bank = 0x4000 * int(self.rom_bank)
		return self.cart.data[int(bank)+int(offset)]
	case addr < 0xA000:
		// VRAM
	case addr < 0xC000:
		// 8KB Switchable RAM bank
		if !self.ram_enable {
			panic("Reading from external ram while disabled: {:04X}") // addr,
		}
		var addr_within_ram = (int(self.ram_bank) * 0x2000) + (int(addr) - 0xA000)
		if addr_within_ram > self.cart.ram_size {
			// this should never happen because we die on ram_bank being
			// set to a too-large value
			panic("Reading from external ram beyond limit: {:04x} ({:02x}:{:04x})")
			//addr_within_ram,
			//self.ram_bank,
			//(addr - 0xA000),
		}
		panic("Cart RAM not supported") // TODO
		// return self.cart.ram[addr_within_ram]
	case addr < 0xD000:
		// work RAM, bank 0
	case addr < 0xE000:
		// work RAM, bankable in CGB
	case addr < 0xFE00:
		// ram[E000-FE00] mirrors ram[C000-DE00]
		return self.data[addr-0x2000]
	case addr < 0xFEA0:
		// Sprite attribute table
	case addr < 0xFF00:
		// Unusable
		return 0xFF
	case addr < 0xFF80:
		// IO Registers
	case addr < 0xFFFF:
		// High RAM
	default:
		// IE Register
	}
	return self.data[addr]
}

func (self *RAM) set(addr uint16, val uint8) {
	switch {
	case addr < 0x2000:
		self.ram_enable = val != 0
	case addr < 0x4000:
		self.rom_bank_low = val
		self.rom_bank = (self.rom_bank_high << 5) | self.rom_bank_low
		if self.debug {
			print(
				"rom_bank set to {}/{}", self.rom_bank, self.cart.rom_size/0x2000,
			)
		}
		if int(self.rom_bank)*0x2000 > int(self.cart.rom_size) {
			panic("Set rom_bank beyond the size of ROM")
		}
	case addr < 0x6000:
		if self.ram_bank_mode {
			self.ram_bank = val
			if self.debug {
				print(
					"ram_bank set to {}/{}",
					self.ram_bank,
					self.cart.ram_size/0x2000,
				)
			}
			if int(self.ram_bank)*0x2000 > int(self.cart.ram_size) {
				panic("Set ram_bank beyond the size of RAM")
			}
		} else {
			self.rom_bank_high = val
			self.rom_bank = (self.rom_bank_high << 5) | self.rom_bank_low
			if self.debug {
				print(
					"rom_bank set to {}/{}",
					self.rom_bank,
					self.cart.rom_size/0x2000,
				)
			}
			if int(self.rom_bank)*0x2000 > int(self.cart.rom_size) {
				panic("Set rom_bank beyond the size of ROM")
			}
		}
	case addr < 0x8000:
		self.ram_bank_mode = val != 0
		if self.debug {
			print("ram_bank_mode set to {}", self.ram_bank_mode)
		}
	case addr < 0xA000:
		// VRAM
		// TODO: if writing to tile RAM, update tiles in IO class?
	case addr < 0xC000:
		// external RAM, bankable
		if !self.ram_enable {
			panic("Writing to external ram while disabled: {:04x}={:02x}")
			// , addr, val,
		}
		var addr_within_ram = (int(self.ram_bank) * 0x2000) + (int(addr) - 0xA000)
		if self.debug {
			print(
				"Writing external RAM: {:04x}={:02x} ({:02x}:{:04x})",
				addr_within_ram,
				val,
				self.ram_bank,
				(addr - 0xA000),
			)
		}
		if addr_within_ram >= self.cart.ram_size {
			// panic!("Writing beyond RAM limit")
			return
		}
		panic("Cart RAM not supported") // TODO
		// self.cart.ram[addr_within_ram] = val
	case addr < 0xD000:
		// work RAM, bank 0
	case addr < 0xE000:
		// work RAM, bankable in CGB
	case addr < 0xFE00:
		// ram[E000-FE00] mirrors ram[C000-DE00]
		self.data[addr-0x2000] = val
	case addr < 0xFEA0:
		// Sprite attribute table
	case addr < 0xFF00:
		// Unusable
		if self.debug {
			print("Writing to invalid ram: {:04x} = {:02x}", addr, val)
		}
	case addr < 0xFF80:
		// IO Registers
		// if addr == IO::SCX as u16 {
		//     println!("LY = {}, SCX = {}", self.get(IO::LY), val);
		// }
	case addr < 0xFFFF:
		// High RAM
	default:
		// IE Register
	}

	self.data[addr] = val
}

func (self *RAM) _and(addr uint16, val uint8) {
	self.set(addr, self.get(addr)&val)
}
func (self *RAM) _or(addr uint16, val uint8) {
	self.set(addr, self.get(addr)|val)
}
func (self *RAM) _inc(addr uint16) {
	self.set(addr, self.get(addr)+1)
}
