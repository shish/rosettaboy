RosettaBoy
==========
Trying to implement a gameboy emulator in a bunch of languages for my own
amusement and education. The main goals are:

- Readability of the code
- Consistency across langauges
- Idiomatic use of language features
- Basic playability

Notably, 100% accuracy is not a goal - if Tetris works perfectly then I'm
happy, if other games require more obscure hardware features, then I'll
weigh up whether or not the feature is worth the complexity.

Also yes, "consistent across languages" and "idiomatic" can be at odds -
there are subjective compromises to be made, but for the most part that
doesn't seem to be a huge problem.

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

Pull requests to translate into new languages, or fleshing out existing
languages, are very welcome :)

Completeness
------------
| Feature                            | Python    | C++       | Rust      |
| -------                            | -------   | ---       | ----      |
| gblargh's CPU test suite           |  &check;  |  &check;  |  &check;  |
| silent / headless                  |  &check;  |  &check;  |  &check;  |
| scaled output                      |  &check;  |  &check;  |  &check;  |
| debug build fps                    |  5        |  150      |  80       |
| release build fps                  |  5        |  350      |  500      |
| CPU logging                        |  &check;  |  &check;  |  &check;  |
| keyboard input                     |  &check;  |  &check;  |  &check;  |
| gamepad input                      |  &cross;  |  &cross;  |  &check;  |
| turbo button                       |  &cross;  |  &check;  |  &cross;  |
| audio                              |  &cross;  |  off-key  |  glitchy  |
| memory mapping                     |  &check;  |  &check;  |  &check;  |
| scanline rendering                 |  &cross;  |  &check;  |  &check;  |
| bank swapping                      |  ?        |  ?        |  ?        |
| CPU interrupts                     |  &check;  |  &check;  |  &check;  |
| GPU interrupts                     |  &cross;  |  &check;  |  &check;  |
