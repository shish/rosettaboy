use anyhow::{anyhow, Result};
use std::time::{Duration, SystemTime};

pub struct Clock {
    cycle: u32,
    frame: u32,
    last_frame_start: SystemTime,
    start: SystemTime,
    profile: u32,
    turbo: bool,
}

impl Clock {
    pub fn new(profile: u32, turbo: bool) -> Clock {
        let start = SystemTime::now();
        let last_frame_start = SystemTime::now();

        Clock {
            cycle: 0,
            frame: 0,
            last_frame_start,
            start,
            profile,
            turbo,
        }
    }

    pub fn tick(&mut self) -> Result<()> {
        self.cycle += 1;

        // Do a whole frame's worth of sleeping at the start of each frame
        if self.cycle % 17556 == 20 {
            // Sleep if we have time left over
            let time_spent = SystemTime::now().duration_since(self.last_frame_start)?;
            let time_per_frame = Duration::from_millis((1000.0 / 60.0) as u64);
            if !self.turbo && time_spent < time_per_frame {
                let sleep_time = time_per_frame - time_spent;
                ::std::thread::sleep(sleep_time);
            }
            self.last_frame_start = SystemTime::now();

            // Exit if we've hit the frame limit
            if self.profile != 0 && self.frame > self.profile {
                let duration = SystemTime::now().duration_since(self.start)?.as_secs_f32();
                return Err(anyhow!(
                    "Emulated {} frames in {:.2}s ({:.2}fps)",
                    self.profile,
                    duration,
                    self.profile as f32 / duration
                ));
            }

            self.frame += 1;
        }

        Ok(())
    }
}
