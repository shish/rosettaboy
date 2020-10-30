#!/usr/bin/env python3

from os import environ
environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'

import sys
from typing import List
from cart import Cart
from cpu import CPU, OpNotImplemented
from gpu import GPU
from clock import Clock
import argparse

def info(cart):
    with open(cart, "rb") as fp:
        data = fp.read()
    cart = Cart(data)
    print(cart)
    # cpu = cpu.CPU(cart)
    # print("%d%% of instructions implemented" % (sum(op is not None for op in cpu.ops)/256*100))
    # for n, op in enumerate(cpu.ops):
    #     print("%02X %s" % (n, op.name if op else "-"))


def run(args):
    cart = Cart(args.rom)
    cpu = CPU(cart, debug=args.debug_cpu)
    clock = Clock(args.profile, args.turbo)

    gpu = None
    if not args.headless:
        gpu = GPU(cpu, debug=args.debug_gpu)

    try:
        while True:
            cpu.tick()
            if gpu and not gpu.tick():
                break
            # if not buttons.tick():
            #     break
            if not clock.tick():
                break
    except OpNotImplemented as e:
        print(e, file=sys.stderr)
    except (Exception, KeyboardInterrupt) as e:
        dump(cpu, str(e))
    finally:
        if gpu:
            gpu.close()


def dump(cpu: CPU, err: str):
    print(f"Error: {err}\nWriting details to crash.txt")
    with open("crash.txt", "w") as fp:
        fp.write(str(err) + "\n\n")
        fp.write(str(cpu._debug_str) + "\n\n")
        fp.write(str(cpu) + "\n\n")
        for n in range(0x0000, 0xFFFF, 0x0010):
            fp.write(("%04X :" + (" %02X" * 16) + "\n") % (n, *cpu.ram[n : n + 0x0010]))


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
    )
    args = parser.parse_args()

    if args.info:
        info(args.rom)
    else:
        run(args)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
