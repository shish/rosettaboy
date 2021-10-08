package main

type Clock struct {
	profile int
	turbo   bool
	fps     bool
}

func NewClock(profile int, turbo, fps bool) Clock {
	return Clock{profile, turbo, fps}
}

func (self Clock) tick() bool {
	return true
}
