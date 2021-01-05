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
- every tick: `update_buttons()`
- once per frame: `handle_inputs()`

`update_buttons()`
------------------
- update the I/O registers based on which buttons are currently held

`handle_inputs()`
-----------------
- Accept input events from SDL
