package main

import "github.com/veandco/go-sdl2/sdl"

type APU struct {
	debug  bool
	cpu    *CPU
	silent bool
}

func NewAPU(cpu *CPU, debug bool, silent bool) (*APU, error) {
	if !silent {
		if err := sdl.Init(uint32(sdl.INIT_AUDIO)); err != nil {
			return nil, err
		}
	}

	return &APU{debug, cpu, silent}, nil
}
