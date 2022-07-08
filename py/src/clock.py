import sdl2
import time


class Clock:
    def __init__(self, profile: int, turbo: bool):
        self.cycle = 0
        self.frame = 0
        self.start = time.time()
        self.profile = profile
        self.turbo = turbo
        self.last_frame_start = 0

    def tick(self) -> bool:
        self.cycle += 1

        # Do a whole frame's worth of sleeping at the start of each frame
        if self.cycle % 17556 == 20:
            # Sleep if we have time left over
            time_spent = sdl2.SDL_GetTicks() - self.last_frame_start
            sleep_for = (1000 / 60) - time_spent
            if sleep_for > 0 and not self.turbo:  # and not self.buttons.turbo:
                sdl2.SDL_Delay(int(sleep_for))
            self.last_frame_start = sdl2.SDL_GetTicks()

            # Exit if we've hit the frame limit
            if self.profile != 0 and self.frame > self.profile:
                duration = time.time() - self.start
                print(
                    "Emulated %d frames in %.2fs (%.2ffps)\n"
                    % (self.profile, duration, self.profile / duration)
                )
                return False

            self.frame += 1

        return True
