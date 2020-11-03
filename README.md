RosettaBoy
==========
Trying to implement a gameboy emulator in a bunch of languages for my own
amusement and education. The main goals are readability and basic playability,
100% accuracy is not a goal.

So far all the implementations follow a fairly standard layout, with each
module teaching me how to do a new thing. In fact they're all so similar,
I wrote one copy of the documentation for all the implementations:

- [main](docs/main.md): argument parsing
- [cpu](docs/cpu.md): CPU emulation
- [gpu](docs/gpu.md): graphical processing
- [apu](docs/apu.md): audio processing
- [buttons](docs/buttons.md): user input
- [cart](docs/cart.md): binary file I/O and parsing
- [clock](docs/clock.md): timing / sleeping
- [consts](docs/consts.md): lists of constant values
- [ram](docs/ram.md): array access where some array values are special

Completeness
------------

| Feature                                           | Py  | C++ | Rs  |
| -------                                           | --- | --- | --- |
| glbargh's CPU test suite          | Fails `interrupts`  |  y  |  y  |
| audio                                        |  n  |  off-key |  n  |
| gamepad                                           |  n  |  n  |  y  |
| memory mapping                                    |  n  |  y  |  y  |
| scanline rendering                                |  n  |  n  |  y  |
