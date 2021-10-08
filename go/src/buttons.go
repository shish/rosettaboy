package main

type Buttons struct {
	cpu      CPU
	headless bool
	need_interrupt bool
	cycle int
	up, down, left, right bool
	a, b, start, select_ bool
}

func NewButtons(cpu CPU, headless bool) Buttons {
	return Buttons {
		cpu,
		headless,
		false, 0,
		false, false, false, false,
		false, false, false, false,
	}
}

func (self Buttons) tick() bool {
	self.cycle += 1
	self.update_buttons()
	if self.need_interrupt {
		self.cpu.stop = false
		self.cpu.interrupt(INTERRUPT_JOYPAD)
		self.need_interrupt = false
	}
	if self.cycle % 17556 == 20 {
		return self.handle_inputs()
	} else {
		return true
	}
}

func (self Buttons) update_buttons() {
	// TODO
}

func (self Buttons) handle_inputs() bool {
	// TODO
	return true
}