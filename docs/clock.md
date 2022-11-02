Clock
=====

`tick()`
--------
- once per frame, sleep for however much time we have left in the frame
- if `--turbo`, don't sleep
- if user is holding left-shift, don't sleep
- if our frame number is >= --frames, or elapsed time >= --profile, exit