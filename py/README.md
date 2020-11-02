RosettaBoy Python
=================
My first ever attempt at an emulator

Usage
-----
```
python3 -m venv venv
source venv/bin/activate
python3 -m pip install pygame
./main.py game.gb
```

Requirements
------------
- Python 3.6+
- PyGame

Completeness
------------
- Passes most of gblargh's CPU test suite, except for #2 (`Interrupts`) :|
- RAM is just implemented as a flat array, when in reality
  there's a memory controller sitting between the CPU and other hardware
  which is supposed to be doing things like bank switching. This means that
  basically nothing except the boot screen and basic single-bank test ROMs
  are able to run :(
- Sound is not even started :(
- Backgrounds and sprites are rendered all at once, instead of a line at
  a time :(