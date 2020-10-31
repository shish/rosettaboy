#!/usr/bin/env python3

from os import environ
environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'

import pygame
import sys
from typing import List
from cart import Cart
from cpu import CPU, OpNotImplemented
from gpu import GPU
from clock import Clock
from buttons import Buttons
import argparse


def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom")
    parser.add_argument(
        "--info", action="store_true", default=False, help="Show ROM metadata"
    )
    parser.add_argument("-c", "--debug-cpu", action="store_true", default=False)
    parser.add_argument("-g", "--debug-gpu", action="store_true", default=False)
    parser.add_argument("-H", "--headless", action="store_true", default=False)
    parser.add_argument("-t", "--turbo", action="store_true", default=False)
    parser.add_argument(
        "-p",
        "--profile",
        type=int,
        help="Exit after N frames",
        default=0,
    )
    args = parser.parse_args()

    if args.info:
        print(Cart(args.rom))
        return

    pygame.init()
    try:
        cart = Cart(args.rom)
        buttons = Buttons()
        cpu = CPU(cart, debug=args.debug_cpu)
        clock = Clock(args.profile, args.turbo)

        gpu = None
        if not args.headless:
            gpu = GPU(cpu, debug=args.debug_gpu)

        while True:
            cpu.tick()
            if gpu and not gpu.tick():
                break
            if not buttons.tick():
                break
            if not clock.tick():
                break
    #except Exception as e:
    #    print(f"Error: {e}\nWriting details to crash.txt")
    #    with open("crash.txt", "w") as fp:
    #        fp.write(str(e) + "\n\n")
    #        fp.write(str(cpu._debug_str) + "\n\n")
    #        fp.write(str(cpu) + "\n\n")
    #        for n in range(0x0000, 0xFFFF, 0x0010):
    #            fp.write(("%04X :" + (" %02X" * 16) + "\n") % (n, *cpu.ram[n : n + 0x0010]))
    except KeyboardInterrupt:
        pass
    finally:
        pygame.quit()

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
