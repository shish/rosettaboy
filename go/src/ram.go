package main

import (
	"fmt"
	"io/ioutil"
)

const ROM_BANK_SIZE = 0x4000
const RAM_BANK_SIZE = 0x2000

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

func (ram *RAM) get(addr uint16) uint8 {
	var val = ram.data[addr]
	switch {
	case addr < 0x4000:
		// ROM bank 0
		if ram.data[IO_BOOT] == 0 && addr < 0x100 {
			val = ram.boot[addr]
		} else {
			val = ram.cart.data[addr]
		}
	case addr < 0x8000:
		// Switchable ROM bank
		// TODO: array bounds check
		var bank = int(ram.rom_bank) * ROM_BANK_SIZE
		var offset = addr - 0x4000
		val = ram.cart.data[int(bank)+int(offset)]
	case addr < 0xA000:
		// VRAM
	case addr < 0xC000:
		// 8KB Switchable RAM bank
		if !ram.ram_enable {
			panic("Reading from external ram while disabled: {:04X}") // addr,
		}
		var bank = uint32(ram.ram_bank) * RAM_BANK_SIZE
		var offset = uint32(addr) - 0xA000
		if bank+offset >= ram.cart.ram_size {
			// this should never happen because we die on ram_bank being
			// set to a too-large value
			panic("Reading from external ram beyond limit: {:04x} ({:02x}:{:04x})")
			//addr_within_ram,
			//ram.ram_bank,
			//(addr - 0xA000),
		}
		panic("Cart RAM not supported") // TODO
		// return ram.cart.ram[bank + offset]
	case addr < 0xD000:
		// work RAM, bank 0
	case addr < 0xE000:
		// work RAM, bankable in CGB
	case addr < 0xFE00:
		// ram[E000-FE00] mirrors ram[C000-DE00]
		val = ram.data[addr-0x2000]
	case addr < 0xFEA0:
		// Sprite attribute table
	case addr < 0xFF00:
		// Unusable
		val = 0xFF
	case addr < 0xFF80:
		// IO Registers
	case addr < 0xFFFF:
		// High RAM
	default:
		// IE Register
	}

	if ram.debug {
		fmt.Printf("ram[%04X] -> %02X\n", addr, val)
	}
	return val
}

func (ram *RAM) set(addr uint16, val uint8) {
	if ram.debug {
		fmt.Printf("ram[%04X] <- %02X\n", addr, val)
	}
	switch {
	case addr < 0x2000:
		ram.ram_enable = val != 0
	case addr < 0x4000:
		ram.rom_bank_low = val
		ram.rom_bank = (ram.rom_bank_high << 5) | ram.rom_bank_low
		if ram.debug {
			println(
				"rom_bank set to {}/{}", ram.rom_bank, ram.cart.rom_size/ROM_BANK_SIZE,
			)
		}
		if int(ram.rom_bank)*ROM_BANK_SIZE > int(ram.cart.rom_size) {
			panic("Set rom_bank beyond the size of ROM")
		}
	case addr < 0x6000:
		if ram.ram_bank_mode {
			ram.ram_bank = val
			if ram.debug {
				println(
					"ram_bank set to {}/{}",
					ram.ram_bank,
					ram.cart.ram_size/RAM_BANK_SIZE,
				)
			}
			if int(ram.ram_bank)*RAM_BANK_SIZE > int(ram.cart.ram_size) {
				panic("Set ram_bank beyond the size of RAM")
			}
		} else {
			ram.rom_bank_high = val
			ram.rom_bank = (ram.rom_bank_high << 5) | ram.rom_bank_low
			if ram.debug {
				println(
					"rom_bank set to {}/{}",
					ram.rom_bank,
					ram.cart.rom_size/ROM_BANK_SIZE,
				)
			}
			if int(ram.rom_bank)*ROM_BANK_SIZE > int(ram.cart.rom_size) {
				panic("Set rom_bank beyond the size of ROM")
			}
		}
	case addr < 0x8000:
		ram.ram_bank_mode = val != 0
		if ram.debug {
			println("ram_bank_mode set to {}", ram.ram_bank_mode)
		}
	case addr < 0xA000:
		// VRAM
		// TODO: if writing to tile RAM, update tiles in IO class?
	case addr < 0xC000:
		// external RAM, bankable
		if !ram.ram_enable {
			panic("Writing to external ram while disabled: {:04x}={:02x}")
			// , addr, val,
		}
		var bank = uint32(ram.ram_bank) * RAM_BANK_SIZE
		var offset = uint32(addr) - 0xA000
		if ram.debug {
			println(
				"Writing external RAM: {:04x}={:02x} ({:02x}:{:04x})",
				bank+offset,
				val,
				ram.ram_bank,
				(addr - 0xA000),
			)
		}
		if bank+offset >= ram.cart.ram_size {
			panic("Writing beyond RAM limit")
		}
		panic("Cart RAM not supported") // TODO
		// ram.cart.ram[bank + offset] = val
	case addr < 0xD000:
		// work RAM, bank 0
	case addr < 0xE000:
		// work RAM, bankable in CGB
	case addr < 0xFE00:
		// ram[E000-FE00] mirrors ram[C000-DE00]
		ram.data[addr-0x2000] = val
	case addr < 0xFEA0:
		// Sprite attribute table
	case addr < 0xFF00:
		// Unusable
		if ram.debug {
			println("Writing to invalid ram: {:04x} = {:02x}", addr, val)
		}
	case addr < 0xFF80:
		// IO Registers
		// if addr == IO::SCX as u16 {
		//     println!("LY = {}, SCX = {}", ram.get(IO::LY), val);
		// }
	case addr < 0xFFFF:
		// High RAM
	default:
		// IE Register
	}

	ram.data[addr] = val
}
