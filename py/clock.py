import pygame

class Clock:
    def __init__(self, profile: int, turbo: bool):
        self.cycle = 0
        self.frame = 0
        self.profile = profile
        self.turbo = turbo
        self.pyclock = pygame.time.Clock()

    def tick(self) -> bool:
        if self.cycle > 70224:
            self.cycle = 0

            # Sleep if we have time left over
            if not self.turbo:
                self.pyclock.tick(60)

            # Exit if we've hit the frame limit
            if self.profile != 0 and self.frame > self.profile:
                return False

            self.frame += 1
        self.cycle += 1
        return True

