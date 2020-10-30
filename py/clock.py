
class Clock:
    def __init__(self, profile: int, turbo: bool):
        self.cycle = 0
        self.frame = 0
        self.profile = profile
        self.turbo = turbo

    def tick(self) -> bool:
        if self.cycle > 70224:
            self.cycle = 0

            # Sleep if we have time left over
            sleep_happens_in_gpu = """
            u32 time_spent = (SDL_GetTicks() - last_frame_start);
            i32 sleep_for = (1000 / 60) - time_spent;
            if(sleep_for > 0 && !this->turbo && !this->buttons->turbo) {
                SDL_Delay(sleep_for);
            }
            last_frame_start = SDL_GetTicks();
            """

            # Exit if we've hit the frame limit
            if self.profile != 0 and self.frame > self.profile:
                return False

            self.frame += 1
        self.cycle += 1
        return True

