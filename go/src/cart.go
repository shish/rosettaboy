package main

import (
	"io/ioutil"
)

type Cart struct {
	data             []byte
	logo             []byte
	name             string
	is_gbc           bool
	licensee         int
	is_sgb           bool
	cart_type        int // CartType
	rom_size         int
	ram_size         int
	destination      int // Destination
	old_licensee     int // OldLicensee
	rom_version      int
	complement_check int
	checksum         int
}

const KB = 1024
const MB = 1024 * 1024

func parse_rom_size(val uint8) uint32 {
	switch val {
	case 0:
		return 32 * KB
	case 1:
		return 64 * KB
	case 2:
		return 128 * KB
	case 3:
		return 256 * KB
	case 4:
		return 512 * KB
	case 5:
		return 1 * MB
	case 6:
		return 2 * MB
	case 7:
		return 4 * MB
	case 8:
		return 8 * MB
	case 0x52:
		return 1*MB + 128*KB
	case 0x53:
		return 1*MB + 256*KB
	case 0x54:
		return 1*MB + 512*KB
	default:
		return 0
	}
}

func parse_ram_size(val uint8) uint32 {
	switch val {
	case 0:
		return 0
	case 1:
		return 2 * KB
	case 2:
		return 8 * KB
	case 3:
		return 32 * KB
	case 4:
		return 128 * KB
	case 5:
		return 64 * KB
	default:
		return 0
	}
}

func NewCart(rom string) Cart {
	var data, err = ioutil.ReadFile(rom)
	if err != nil {
		panic(err)
	}

	var logo = data[0x0104 : 0x0104+48]
	var name = data[0x0134 : 0x0134+16]
	var is_gbc = data[0x143] == 0x80 // 0x80 = works on both, 0xC0 = colour only
	var licensee = uint16(data[0x144])<<8 | uint16(data[0x145])
	var is_sgb = data[0x146] == 0x03
	var cart_type = data[0x147]
	var rom_size = parse_rom_size(data[0x148])
	var ram_size = parse_ram_size(data[0x149])
	var destination = data[0x14A]
	var old_licensee = data[0x14B]
	var rom_version = data[0x14C]
	var complement_check = data[0x14D]
	var checksum = uint16(data[0x14E])<<8 | uint16(data[0x14F])

	var logo_checksum uint16 = 0
	for i := range logo {
		logo_checksum += uint16(i)
	}
	if logo_checksum != 5446 {
		println("Logo checksum failed")
	}

	var header_checksum uint16 = 25
	for i := 0x0134; i < 0x014E; i++ {
		header_checksum += uint16(data[i])
	}
	if (header_checksum & 0xFF) != 0 {
		println("Header checksum failed")
	}

	return Cart{
		data,
		logo,
		string(name),
		is_gbc,
		int(licensee),
		is_sgb,
		int(cart_type),
		int(rom_size),
		int(ram_size),
		int(destination),
		int(old_licensee),
		int(rom_version),
		int(complement_check),
		int(checksum),
	}
}
