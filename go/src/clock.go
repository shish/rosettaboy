package main

import "fmt"
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

func NewClock(buttons *Buttons, profile int, turbo bool) Clock {
	if err := sdl.Init(uint32(sdl.INIT_TIMER)); err != nil {
		panic(err)
	}

	return Clock{buttons, 0, 0, sdl.GetTicks(), sdl.GetTicks(), profile, turbo}
}

func (self *Clock) tick() bool {
	self.cycle++

	// Do a whole frame's worth of sleeping at the start of each frame
	if self.cycle%17556 == 20 {
		// Sleep if we have time left over
		time_spent := (sdl.GetTicks() - uint32(self.last_frame_start))
		sleep_for := (1000 / 60) - int32(time_spent)
		if sleep_for > 0 && !self.turbo && !self.buttons.turbo {
			sdl.Delay(uint32(sleep_for))
		}
		self.last_frame_start = sdl.GetTicks()

		// Exit if we've hit the frame limit
		if self.profile != 0 && self.frame > self.profile {
            var duration = (float32)(sdl.GetTicks() - self.start) / 1000.0;
			fmt.Printf(
				"Hit frame limit after %.2fs (%.2ffps)\n",
				duration,
				float32(self.profile) / duration,
			)
			return false
		}

		self.frame++
	}

	return true
}
