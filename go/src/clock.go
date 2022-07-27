package main

import "github.com/veandco/go-sdl2/sdl"

type Clock struct {
	buttons          *Buttons
	cycle            int
	frame            int
	last_frame_start uint32
	start            uint32
	profile          int
	turbo            bool
}

func NewClock(buttons *Buttons, profile int, turbo bool) (*Clock, error) {
	if err := sdl.Init(uint32(sdl.INIT_TIMER)); err != nil {
		return nil, err
	}

	return &Clock{buttons, 0, 0, sdl.GetTicks(), sdl.GetTicks(), profile, turbo}, nil
}

func (clock *Clock) tick() error {
	clock.cycle++

	// Do a whole frame's worth of sleeping at the start of each frame
	if clock.cycle%17556 == 20 {
		// Sleep if we have time left over
		time_spent := (sdl.GetTicks() - uint32(clock.last_frame_start))
		sleep_for := (1000 / 60) - int32(time_spent)
		if sleep_for > 0 && !clock.turbo && !clock.buttons.turbo {
			sdl.Delay(uint32(sleep_for))
		}
		clock.last_frame_start = sdl.GetTicks()

		// Exit if we've hit the frame limit
		if clock.profile != 0 && clock.frame > clock.profile {
			var duration = (float32)(sdl.GetTicks()-clock.start) / 1000.0
			return &Timeout{EmuError: EmuError{ExitCode: 0}, Frames: clock.profile, Duration: duration};
		}

		clock.frame++
	}
	return nil
}
