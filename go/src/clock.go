package main

type Clock struct {
	cycle   int
	frame   int
	profile int
	turbo   bool
	fps     bool
}

func NewClock(profile int, turbo, fps bool) Clock {
	return Clock{0, 0, profile, turbo, fps}
}

func (self Clock) tick() bool {
	// TODO: sleep
	return true
}
