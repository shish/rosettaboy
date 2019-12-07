use std::time::{Duration, SystemTime, UNIX_EPOCH};

pub struct Clock {
    start: SystemTime,
    last_frame_start: Duration,
    cycle: u32,
    frame: u32,
    profile: bool,
    turbo: bool,
}

impl Clock {
    pub fn init(profile: bool, turbo: bool) -> Clock {
        let start = SystemTime::now();
        let last_frame_start = start.duration_since(UNIX_EPOCH).expect("time");

        Clock {
            start,
            last_frame_start,
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

            let time_spent =
                self.start.duration_since(UNIX_EPOCH).expect("time") - self.last_frame_start;
            // printf("Frame took %d/%d ticks\n", time_spent, 1000/60);

            // sleep_for can be <= 0 if our last frame processing time was more than 16ms
            let sleep_for = Duration::from_millis((1000.0 / 60.0) as u64) - time_spent;
            if !self.turbo && sleep_for.as_millis() > 0 {
                ::std::thread::sleep(sleep_for);
            }
            self.last_frame_start = self.start.duration_since(UNIX_EPOCH).expect("time");

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
