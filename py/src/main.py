#!/usr/bin/env python3

from sdl2 import SDL_Quit
import sys
from typing import List

from .cart import Cart
from .cpu import CPU
from .errors import EmuError
from .gpu import GPU
from .clock import Clock
from .buttons import Buttons
from .ram import RAM
import argparse


def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom")
    parser.add_argument(
        "--info", action="store_true", default=False, help="Show ROM metadata"
    )
    parser.add_argument("-c", "--debug-cpu", action="store_true", default=False)
    parser.add_argument("-g", "--debug-gpu", action="store_true", default=False)
    parser.add_argument("-r", "--debug-ram", action="store_true", default=False)
    parser.add_argument("-H", "--headless", action="store_true", default=False)
    parser.add_argument("-S", "--silent", action="store_true", default=False)
    parser.add_argument("-t", "--turbo", action="store_true", default=False)
    parser.add_argument(
        "-p",
        "--profile",
        type=int,
        help="Exit after N frames",
        default=0,
        metavar="N",
    )
    args = parser.parse_args(argv[1:])

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
