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

func NewButtons(cpu *CPU, headless bool) (*Buttons, error) {
	if !headless {
		if err := sdl.Init(uint32(sdl.INIT_EVENTS | sdl.INIT_GAMECONTROLLER | sdl.INIT_JOYSTICK)); err != nil {
			return nil, err
		}
	}

	return &Buttons{
		cpu,
		headless,
		false, 0,
		false, false, false, false,
		false, false, false, false,
		false,
	}, nil
}

func (buttons *Buttons) tick() error {
	buttons.cycle += 1
	buttons.update_buttons()
	if buttons.need_interrupt {
		buttons.cpu.stop = false
		buttons.cpu.interrupt(INT_JOYPAD)
		buttons.need_interrupt = false
	}
	if buttons.cycle%17556 == 20 {
		return buttons.handle_inputs()
	}
	return nil
}

func (buttons *Buttons) update_buttons() {
	var JOYP = ^buttons.cpu.ram.data[IO_JOYP]
	JOYP &= 0xF0
	if JOYP&JOYPAD_MODE_DPAD > 0 {
		if buttons.up {
			JOYP |= JOYPAD_UP
		}
		if buttons.down {
			JOYP |= JOYPAD_DOWN
		}
		if buttons.left {
			JOYP |= JOYPAD_LEFT
		}
		if buttons.right {
			JOYP |= JOYPAD_RIGHT
		}
	}
	if JOYP&JOYPAD_MODE_BUTTONS > 0 {
		if buttons.b {
			JOYP |= JOYPAD_B
		}
		if buttons.a {
			JOYP |= JOYPAD_A
		}
		if buttons.start {
			JOYP |= JOYPAD_START
		}
		if buttons.select_ {
			JOYP |= JOYPAD_SELECT
		}
	}
	buttons.cpu.ram.data[IO_JOYP] = ^JOYP
}

func (buttons *Buttons) handle_inputs() error {
	if buttons.headless {
		return nil
	}

	for event := sdl.PollEvent(); event != nil; event = sdl.PollEvent() {
		switch t := event.(type) {
		case *sdl.QuitEvent:
			return &Quit{}
		case *sdl.KeyboardEvent:
			switch t.Type {
			case sdl.KEYDOWN:
				buttons.need_interrupt = true
				switch t.Keysym.Sym {
				case sdl.K_ESCAPE:
					return &Quit{}
				case sdl.K_LSHIFT:
					buttons.turbo = true
					buttons.need_interrupt = false
				case sdl.K_UP:
					buttons.up = true
				case sdl.K_DOWN:
					buttons.down = true
				case sdl.K_LEFT:
					buttons.left = true
				case sdl.K_RIGHT:
					buttons.right = true
				case sdl.K_z:
					buttons.b = true
				case sdl.K_x:
					buttons.a = true
				case sdl.K_RETURN:
					buttons.start = true
				case sdl.K_SPACE:
					buttons.select_ = true
				default:
					buttons.need_interrupt = false
				}
			case sdl.KEYUP:
				switch t.Keysym.Sym {
				case sdl.K_LSHIFT:
					buttons.turbo = false
				case sdl.K_UP:
					buttons.up = false
				case sdl.K_DOWN:
					buttons.down = false
				case sdl.K_LEFT:
					buttons.left = false
				case sdl.K_RIGHT:
					buttons.right = false
				case sdl.K_z:
					buttons.b = false
				case sdl.K_x:
					buttons.a = false
				case sdl.K_RETURN:
					buttons.start = false
				case sdl.K_SPACE:
					buttons.select_ = false
				}
			}
		}
	}

	return nil
}
