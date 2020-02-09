#!/usr/bin/env python3

import sys
from typing import List
from cart import Cart
from cpu import CPU, OpNotImplemented
from lcd import LCD
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
    with open(args.cart, "rb") as fp:
        data = fp.read()
    cart = Cart(data)
    cpu = CPU(cart, debug=args.debug_cpu)

    lcd = None
    if not args.headless:
        lcd = LCD(cpu, debug=args.debug_gpu)

    running = True
    clock = 0
    while running:
        try:
            if not cpu.halt and not cpu.stop:
                clock += cpu.tick()
            else:
                clock += 4
            #if cpu.halt:
            #    print("CPU halted, waiting for interrupt")
            #    break
            #if cpu.stop:
            #    print("CPU stopped, waiting for button")
            #    break

        except OpNotImplemented as e:
            running = False
            # print(cpu)
            print(e, file=sys.stderr)
        except (Exception, KeyboardInterrupt) as e:
            running = False
            dump(cpu, str(e))

        # 4MHz / 60FPS ~= 70000 instructions per frame
        if clock > 70224 or clock > 1000:
            # print(last_frame - time.time())
            clock = 0
            if lcd and not lcd.update():
                running = False

    if lcd:
        lcd.close()


def dump(cpu: CPU, err: str):
    print("Error: %s\nWriting details to crash.txt" % err)
    with open("crash.txt", "w") as fp:
        fp.write(str(err) + "\n\n")
        fp.write(str(cpu._debug_str) + "\n\n")
        fp.write(str(cpu) + "\n\n")
        for n in range(0x0000, 0xFFFF, 0x0010):
            fp.write(("%04X :" + (" %02X" * 16) + "\n") % (n, *cpu.ram[n:n + 0x0010]))


def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode")
    parser.add_argument("cart")
    parser.add_argument("-d", "--debug-cpu", action="store_true", default=False)
    parser.add_argument("-D", "--debug-gpu", action="store_true", default=False)
    parser.add_argument("--headless", action="store_true", default=False)
    args = parser.parse_args()

    if args.mode == "info":
        info(args.cart)

    if args.mode == "run":
        run(args)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
