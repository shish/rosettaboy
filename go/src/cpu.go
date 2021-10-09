package main

type CPU struct {
	debug bool
	ram   *RAM
	stop  bool
	halt  bool
}

func NewCPU(ram *RAM, debug bool) CPU {
	return CPU{debug, ram, false, false}
}

func (self *CPU) tick() bool {
	// TODO
	return true
}

func (self *CPU) interrupt(i byte) {
	// Set a given interrupt bit - on the next tick, if the interrupt
	// handler for this interrupt is enabled (and interrupts in general
	// are enabled), then the interrupt handler will be called.
	self.ram.data[0] |= i // FIXME: IO_IF
	self.halt = false     // interrupts interrupt HALT state
}
