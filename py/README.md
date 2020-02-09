# spygab
Python GameBoy Emulator

My first ever attempt at an emulator, it passes the core-cpu test suite
(ie all the CPU instructions are implemented correctly, barring some really
weird hardware bugs), but I/O is very incomplete.

In particular RAM is just implemented as a flat array, when in reality
there's a memory controller sitting between the CPU and other hardware
which is supposed to be doing things like bank switching. This means that
basically nothing except the boot screen and basic single-bank test ROMs
are able to run.

## Usage

Stick a gameboy BIOS into boot.gb in the current directory. Finding a BIOS
is left as an exercise to the reader.

```
python3 -m venv .venv
source .venv/bin/activate
pip3 install pygame
./main.py run <myrom.gb> [--debug-gpu] [--debug-cpu] [--headless]
```

## Requirements

- Python 3.6+
- PyGame
