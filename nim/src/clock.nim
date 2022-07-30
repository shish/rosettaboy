import os
import std/times
import std/strformat
import buttons

# FIXME: use getTime() instead of epochTime()
type
    Clock* = object
        buttons: buttons.Buttons
        profile: int
        turbo: bool
        cycle: int
        frame: int
        last_frame_start: float
        start: float

proc create*(buttons: Buttons, profile: int, turbo: bool): Clock =
    return Clock(
      buttons: buttons,
      profile: profile,
      turbo: turbo,
      cycle: 0,
      frame: 0,
      last_frame_start: epochTime(),
      start: epochTime(),
    )

proc tick*(self: var Clock) =
    self.cycle += 1

    if self.cycle mod 17556 == 20:
        # Sleep if we have time left over
        let time_spent = epochTime() - self.last_frame_start
        let time_per_frame = 1000 / 60
        if not self.turbo and not self.buttons.turbo and time_spent < time_per_frame:
            let sleep_time = time_per_frame - time_spent
            os.sleep(sleep_time.int)
        self.last_frame_start = epochTime()

        # Exit if we've hit the frame limit
        if self.profile != 0 and self.frame > self.profile:
            let duration = epochTime() - self.start
            # FIXME: not OSError
            raise newException(
              OSError,
              fmt"Emulated {self.profile} frames in {duration:5.2}s ({(self.profile.float/duration).int}fps)"
            )

        self.frame += 1
