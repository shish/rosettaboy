Buttons
=======
Takes user input and updates the input registers

Standard keyboard controls:

- D-Pad -- arrow keys
- B -- Z
- A -- X
- Start -- Enter
- Select -- Space

`init()`
--------
- Set up the intial state of each button (nothing pressed)

`tick()`
--------
- if any button is pressed which wasn't pressed last time, interrupt
- every tick: `update_buttons()`
- once per frame: `handle_inputs()`

- TODO: do we also need to interrupt on button release?
- TODO: do we also need to interrupt even when neither Dpad nor Buttons are selected?


`update_buttons()`
------------------
- update the I/O registers based on which buttons are currently held

Since the hardware uses 0 for pressed and 1 for released, we invert on read and write to keep our logic sensible....

`handle_inputs()`
-----------------
- Accept input events from SDL
