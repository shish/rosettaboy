import pygame
import time


class Clock:
    def __init__(self, profile: int, turbo: bool):
        self.cycle = 0
        self.frame = 0
        self.pyclock = pygame.time.Clock()
        self.start = time.time()
        self.profile = profile
        self.turbo = turbo

    def tick(self) -> bool:
        self.cycle += 1

        # Do a whole frame's worth of sleeping at the start of each frame
        if self.cycle % 17556 == 20:
            # Sleep if we have time left over
            if not self.turbo:
                self.pyclock.tick(60)

            # Exit if we've hit the frame limit
            if self.profile != 0 and self.frame > self.profile:
                duration = time.time() - self.start
                print(
                    "Hit frame limit after %.2fs (%.2ffps)\n"
                    % (duration, self.profile / duration)
                )
                return False

            self.frame += 1

        return True
