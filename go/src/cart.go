package main

import (
	"io/ioutil"
)

type Cart struct {
	data             []byte
	rsts             string
	init             []byte
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

func NewCart(rom string) Cart {
	var data, err = ioutil.ReadFile(rom)
	if err != nil {
		panic(err)
	}

	// TODO: parse fields
	return Cart{
		data,
		"",
		make([]byte, 0),
		make([]byte, 0),
		"TITLE",
		false, 0, false,
		0, 0, 0, 0, 0, 0, 0, 0,
	}
}
