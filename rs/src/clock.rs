use std::time::{Duration, SystemTime};

pub struct Clock {
    start: SystemTime,
    last_frame_start: SystemTime,
    time_per_frame: Duration,
    cycle: u32,
    frame: u32,
    profile: u32,
    turbo: bool,
}

impl Clock {
    pub fn init(profile: u32, turbo: bool) -> Clock {
        let start = SystemTime::now();
        let last_frame_start = SystemTime::now();
        let time_per_frame = Duration::from_millis((1000.0 / 60.0) as u64);

        Clock {
            start,
            last_frame_start,
            time_per_frame,
            cycle: 0,
            frame: 0,
            profile,
            turbo,
        }
    }

    pub fn tick(&mut self) -> bool {
        if self.cycle > 70224 {
            self.cycle = 0;

            // Sleep if we have time left over
            let time_spent = SystemTime::now()
                .duration_since(self.last_frame_start)
                .expect("time");
            if !self.turbo && time_spent < self.time_per_frame {
                ::std::thread::sleep(self.time_per_frame - time_spent);
            }
            self.last_frame_start = SystemTime::now();

            // Exit if we've hit the frame limit
            if self.profile != 0 && self.frame > self.profile {
                println!(
                    "Hit frame limit after {:?}",
                    SystemTime::now().duration_since(self.start).expect("time")
                );
                return false;
            }

            self.frame += 1;
        }
        self.cycle += 1;
        return true;
    }
}
