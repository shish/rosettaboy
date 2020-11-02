GPU
===

init()
------
- create window & buffer surface

tick()
------
- update registers
- fire interrupts
- once per frame: `draw_lcd()`

draw_lcd()
----------
- render the layers and sprites