use std::time::{Duration, SystemTime};

pub struct Clock {
    start: SystemTime,
    last_frame_start: SystemTime,
    time_per_frame: Duration,
    cycle: u32,
    frame: u32,
    profile: bool,
    turbo: bool,
}

impl Clock {
    pub fn init(profile: bool, turbo: bool) -> Clock {
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
        self.cycle += 1;

        let lx = self.cycle % 114;
        let ly = (self.cycle / 114) % 154;
        if lx == 20 && ly == 0 {
            // println!("Frame {}", self.frame);
            self.frame += 1;

            let time_spent = SystemTime::now()
                .duration_since(self.last_frame_start)
                .expect("time");
            //if self.frame % 60 == 0 {
            //    println!("Used {}/{}ms", time_spent.as_millis(), self.time_per_frame.as_millis());
            //}

            // if we're below budget for this frame, sleep the rest of the time
            if !self.turbo && time_spent < self.time_per_frame {
                ::std::thread::sleep(self.time_per_frame - time_spent);
            }
            self.last_frame_start = SystemTime::now();

            if self.profile && self.frame > 60 * 10 {
                println!(
                    "Hit frame limit after {:?}",
                    SystemTime::now().duration_since(self.start).expect("time")
                );
                return false;
            }
        }

        return true;
    }
}
