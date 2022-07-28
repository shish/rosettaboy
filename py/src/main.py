#!/usr/bin/env python3

from sdl2 import SDL_Quit
import sys
from typing import List

from .args import parse_args
from .cart import Cart
from .cpu import CPU
from .errors import EmuError
from .gpu import GPU
from .clock import Clock
from .buttons import Buttons
from .ram import RAM


def main(argv: List[str]) -> int:
    args = parse_args(argv[1:])

    if args.info:
        print(Cart(args.rom))
        return 0

    try:
        cart = Cart(args.rom)
        ram = RAM(cart, debug=args.debug_ram)
        cpu = CPU(ram, debug=args.debug_cpu)
        gpu = GPU(cpu, debug=args.debug_gpu, headless=args.headless)
        buttons = Buttons(cpu, headless=args.headless)
        clock = Clock(buttons, args.profile, args.turbo)

        while True:
            cpu.tick()
            gpu.tick()
            buttons.tick()
            clock.tick()
    except EmuError as e:
        print(e)
        return e.exit_code
    except (KeyboardInterrupt, BrokenPipeError):
        pass
    finally:
        SDL_Quit()

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
