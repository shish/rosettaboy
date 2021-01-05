Clock
=====

`tick()`
--------
- once per frame, sleep for however much time we have left in the frame
- if `--turbo`, don't sleep
- if `--fps`, print out FPS and busy% once per 60 frames (once per second
  if there's no slowdown)