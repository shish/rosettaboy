use anyhow::{anyhow, Result};
use std::time::{Duration, SystemTime};

use crate::buttons;
use crate::errors::ControlledExit;

pub struct Clock {
    cycle: u32,
    frame: u32,
    last_frame_start: SystemTime,
    start: SystemTime,
    frames: u32,
    profile: u32,
    turbo: bool,
}

impl Clock {
    pub fn new(frames: u32, profile: u32, turbo: bool) -> Clock {
        let start = SystemTime::now();
        let last_frame_start = SystemTime::now();

        Clock {
            cycle: 0,
            frame: 0,
            last_frame_start,
            start,
            frames,
            profile,
            turbo,
        }
    }

    pub fn tick(&mut self, buttons: &buttons::Buttons) -> Result<()> {
        self.cycle += 1;

        // Do a whole frame's worth of sleeping at the start of each frame
        if self.cycle % 17556 == 20 {
            // Sleep if we have time left over
            let time_spent = SystemTime::now().duration_since(self.last_frame_start)?;
            let time_per_frame = Duration::from_millis((1000.0 / 60.0) as u64);
            if !self.turbo && !buttons.turbo && time_spent < time_per_frame {
                let sleep_time = time_per_frame - time_spent;
                ::std::thread::sleep(sleep_time);
            }
            self.last_frame_start = SystemTime::now();

            // Exit if we've hit the frame or time limit
            let duration = self
                .last_frame_start
                .duration_since(self.start)?
                .as_secs_f32();
            if (self.frames != 0 && self.frame >= self.frames)
                || (self.profile != 0 && duration >= self.profile as f32)
            {
                return Err(anyhow!(ControlledExit::Timeout(self.frame, duration)));
            }

            self.frame += 1;
        }

        Ok(())
    }
}
