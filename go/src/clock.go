package main

import "fmt"
import "github.com/veandco/go-sdl2/sdl"

type Clock struct {
	buttons          *Buttons
	cycle            int
	frame            int
	profile          int
	turbo            bool
	fps              bool
	last_frame_start uint32
	sleep_duration   uint32
	last_report      uint32
}

func NewClock(buttons *Buttons, profile int, turbo, fps bool) Clock {
	if err := sdl.Init(uint32(sdl.INIT_TIMER)); err != nil {
		panic(err)
	}

	return Clock{buttons, 0, 0, profile, turbo, fps, 0, 0, 0}
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
			self.sleep_duration += uint32(sleep_for)
		}
		self.last_frame_start = sdl.GetTicks()

		// Print FPS once per second
		if self.fps && self.frame%60 == 0 {
			t := sdl.GetTicks()
			fps := 60000.0 / float32(t-self.last_report)
			busy := 1.0 - (float32(self.sleep_duration) / 1000.0)
			fmt.Printf("%.1ffps %.1f%% busy\n", fps, busy*100)
			self.sleep_duration = 0
			self.last_report = t
		}

		// Exit if we've hit the frame limit
		if self.profile != 0 && self.frame > self.profile {
			return false
		}

		self.frame++
	}

	return true
}
