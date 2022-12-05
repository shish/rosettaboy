import argparse

from .cart import Cart
from .cpu import CPU
from .gpu import GPU
from .clock import Clock
from .buttons import Buttons
from .ram import RAM


class GameBoy:
    def __init__(self, args: argparse.Namespace) -> None:
        self.cart = Cart(args.rom)
        self.ram = RAM(self.cart, debug=args.debug_ram)
        self.cpu = CPU(self.ram, debug=args.debug_cpu)
        self.gpu = GPU(self.cpu, debug=args.debug_gpu, headless=args.headless)
        self.buttons = Buttons(self.cpu, headless=args.headless)
        self.clock = Clock(self.buttons, args.frames, args.profile, args.turbo)

    def run(self) -> None:
        while True:
            self.tick()

    def tick(self) -> None:
        self.cpu.tick()
        self.gpu.tick()
        self.buttons.tick()
        self.clock.tick()
