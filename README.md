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
| Feature                            | Python    | C++       | Rust      |
| -------                            | -------   | ---       | ----      |
| gblargh's CPU test suite           |  &check;  |  &check;  |  &check;  |
| silent / headless                  |  &check;  |  &check;  |  &check;  |
| scaled output                      |  &check;  |  &check;  |  &check;  |
| debug build fps                    |  5        |  150      |  80       |
| release build fps                  |  5        |  230      |  250      |
| CPU logging                        |  &check;  |  &check;  |  &check;  |
| keyboard input                     |  &cross;  |  &check;  |  &check;  |
| gamepad input                      |  &cross;  |  &cross;  |  &check;  |
| turbo button                       |  &cross;  |  &check;  |  &cross;  |
| audio                              |  &cross;  |  off-key  |  glitchy  |
| memory mapping                     |  &check;  |  &check;  |  &check;  |
| scanline rendering                 |  &cross;  |  &check;  |  &check;  |
| bank swapping                      |  ?        |  ?        |  ?        |
| CPU interrupts                     |  &check;  |  &check;  |  &check;  |
| GPU interrupts                     |  &cross;  |  &check;  |  &check;  |
