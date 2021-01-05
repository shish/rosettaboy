GPU
===

`init()`
--------
- create window & buffer surface

`tick()`
--------
- update registers
- fire interrupts
- for each frame, call `draw_line()` 144 times and noop (vblank) 10 times
- we draw one line at a time because it's possible to update GPU settings
  multiple times per frame, eg adjusting x-offset for a parallax effect

`draw_line()`
-------------
- figure out what tiles are active on which layers (background, window,
  sprites) and call `paint_tile_line()` for each tile.

`paint_tile_line()`
-------------------
- copy a line of pixels from a tile into the buffer