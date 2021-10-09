package main

// Joypad
const (
	JOYPAD_MODE_BUTTONS = 1 << 5
	JOYPAD_MODE_DPAD    = 1 << 4
	JOYPAD_DOWN         = 1 << 3
	JOYPAD_START        = 1 << 3
	JOYPAD_UP           = 1 << 2
	JOYPAD_SELECT       = 1 << 2
	JOYPAD_LEFT         = 1 << 1
	JOYPAD_B            = 1 << 1
	JOYPAD_RIGHT        = 1 << 0
	JOYPAD_A            = 1 << 0
)

type Buttons struct {
	cpu                   CPU
	headless              bool
	need_interrupt        bool
	cycle                 int
	up, down, left, right bool
	a, b, start, select_  bool
}

func NewButtons(cpu CPU, headless bool) Buttons {
	return Buttons{
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
	if self.cycle%17556 == 20 {
		return self.handle_inputs()
	} else {
		return true
	}
}

func (self Buttons) update_buttons() {
	// Since the hardware uses 0 for pressed and 1 for
	// released, let's invert on read and write to keep
	// our logic sensible....
	var JOYP = ^self.cpu.ram.data[IO_JOYP]
	JOYP &= 0xF0
	if JOYP&JOYPAD_MODE_DPAD > 0 {
		if self.up {
			JOYP |= JOYPAD_UP
		}
		if self.down {
			JOYP |= JOYPAD_DOWN
		}
		if self.left {
			JOYP |= JOYPAD_LEFT
		}
		if self.right {
			JOYP |= JOYPAD_RIGHT
		}
	}
	if JOYP&JOYPAD_MODE_BUTTONS > 0 {
		if self.b {
			JOYP |= JOYPAD_B
		}
		if self.a {
			JOYP |= JOYPAD_A
		}
		if self.start {
			JOYP |= JOYPAD_START
		}
		if self.select_ {
			JOYP |= JOYPAD_SELECT
		}
	}
	self.cpu.ram.data[IO_JOYP] = ^JOYP
}

func (self Buttons) handle_inputs() bool {
	// TODO
	return true
}
