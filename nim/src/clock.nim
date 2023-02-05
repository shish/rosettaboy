import std/os
import std/times
import std/strformat

import buttons
import errors

# FIXME: use getTime() instead of epochTime()
type
    Clock* = ref object
        buttons: buttons.Buttons
        frames: int
        profile: int
        turbo: bool
        cycle: int
        frame: int
        lastFrameStart: float
        start: float

proc create*(buttons: Buttons, frames: int, profile: int, turbo: bool): Clock =
    return Clock(
      buttons: buttons,
      frames: frames,
      profile: profile,
      turbo: turbo,
      cycle: 0,
      frame: 0,
      last_frame_start: epochTime(),
      start: epochTime(),
    )

proc tick*(self: Clock) =
    self.cycle += 1

    if self.cycle mod 17556 == 20:
        # Sleep if we have time left over
        let timeSpent = epochTime() - self.last_frame_start
        let timePerFrame = 1000 / 60
        if not self.turbo and not self.buttons.turbo and time_spent < time_per_frame:
            let sleepTime = timePerFrame - time_spent
            os.sleep(sleep_time.int)
        self.lastFrameStart = epochTime()

        # Exit if we've hit the frame or time limit
        let duration = self.lastFrameStart - self.start
        if (self.frames != 0 and self.frame >= self.frames) or (self.profile != 0 and duration >= (float)self.profile):
            raise errors.Timeout.newException(
                fmt"Emulated {self.frame:5} frames in {duration:5.2f}s ({(self.frame.float/duration).int}fps)"
            )

        self.frame += 1
