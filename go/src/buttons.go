package main

import "github.com/veandco/go-sdl2/sdl"

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
	cpu                   *CPU
	headless              bool
	need_interrupt        bool
	cycle                 int
	up, down, left, right bool
	a, b, start, select_  bool
	turbo                 bool
}

func NewButtons(cpu *CPU, headless bool) Buttons {
	if !headless {
		if err := sdl.Init(uint32(sdl.INIT_EVENTS | sdl.INIT_GAMECONTROLLER | sdl.INIT_JOYSTICK)); err != nil {
			panic(err)
		}
	}

	return Buttons{
		cpu,
		headless,
		false, 0,
		false, false, false, false,
		false, false, false, false,
		false,
	}
}

func (self *Buttons) tick() bool {
	self.cycle += 1
	self.update_buttons()
	if self.need_interrupt {
		self.cpu.stop = false
		self.cpu.interrupt(JOYPAD)
		self.need_interrupt = false
	}
	if self.cycle%17556 == 20 {
		return self.handle_inputs()
	} else {
		return true
	}
}

func (self *Buttons) update_buttons() {
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

func (self *Buttons) handle_inputs() bool {
	if self.headless {
		return true
	}

	for event := sdl.PollEvent(); event != nil; event = sdl.PollEvent() {
		switch t := event.(type) {
		case *sdl.QuitEvent:
			return false
		case *sdl.KeyboardEvent:
			switch t.Type {
			case sdl.KEYDOWN:
				if t.Keysym.Sym == sdl.K_ESCAPE {
					return false
				}
				if t.Keysym.Sym == sdl.K_LSHIFT {
					self.turbo = true
				}

				self.need_interrupt = true
				switch t.Keysym.Sym {
				case sdl.K_UP:
					self.up = true
					break
				case sdl.K_DOWN:
					self.down = true
					break
				case sdl.K_LEFT:
					self.left = true
					break
				case sdl.K_RIGHT:
					self.right = true
					break
				case sdl.K_z:
					self.b = true
					break
				case sdl.K_x:
					self.a = true
					break
				case sdl.K_RETURN:
					self.start = true
					break
				case sdl.K_SPACE:
					self.select_ = true
					break
				default:
					self.need_interrupt = false
					break
				}
			case sdl.KEYUP:
				if t.Keysym.Sym == sdl.K_LSHIFT {
					self.turbo = false
				}

				switch t.Keysym.Sym {
				case sdl.K_UP:
					self.up = false
					break
				case sdl.K_DOWN:
					self.down = false
					break
				case sdl.K_LEFT:
					self.left = false
					break
				case sdl.K_RIGHT:
					self.right = false
					break
				case sdl.K_z:
					self.b = false
					break
				case sdl.K_x:
					self.a = false
					break
				case sdl.K_RETURN:
					self.start = false
					break
				case sdl.K_SPACE:
					self.select_ = false
					break
				}
			}
		}
	}

	return true
}
