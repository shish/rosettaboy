package main

import "github.com/veandco/go-sdl2/sdl"

type Clock struct {
	cycle   int
	frame   int
	profile int
	turbo   bool
	fps     bool
}

func NewClock(profile int, turbo, fps bool) Clock {
	if err := sdl.Init(uint32(sdl.INIT_TIMER)); err != nil {
		panic(err)
	}

	return Clock{0, 0, profile, turbo, fps}
}

func (self *Clock) tick() bool {
	// TODO: sleep
	return true
}
