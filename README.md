RosettaBoy
==========
Trying to implement a gameboy emulator in a bunch of languages for my own
amusement and education. The main goals are readability and basic playability,
100% accuracy is not a goal

So far all the implementations follow a fairly standard layout, with each
module teaching me how to do a new thing

- main: argument parsing
- cpu: CPU-heavy work
- gpu: graphical output
- apu: audio output
- buttons: user input
- cart: binary file I/O and parsing
- clock: timing / sleeping
- consts: lists of constant values
- ram: array access where some array values are special
