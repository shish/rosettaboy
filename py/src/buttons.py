import pygame
import pygame.locals
from .consts import Interrupt, IO_JOYP, Joypad

class Buttons:
    def __init__(self, cpu, headless=False):
        self.cpu = cpu
        self.headless = headless
        self.need_interrupt = False

        self.cycle = 0
        self.up = False
        self.down = False
        self.left = False
        self.right = False
        self.a = False
        self.b = False
        self.start = False
        self.select = False

    def tick(self) -> bool:
        self.cycle += 1
        self.update_buttons()
        if self.need_interrupt:
            self.cpu.stop = False
            self.cpu.interrupt(Interrupt.JOYPAD)
            self.need_interrupt = False
        if self.cycle % 17556 == 20:
            return self.handle_inputs()
        else:
            return True

    def update_buttons(self):
        # Since the hardware uses 0 for pressed and 1 for
        # released, let's invert on read and write to keep
        # our logic sensible....
        JOYP = ~self.cpu.ram[IO_JOYP]
        JOYP &= 0xF0
        if JOYP & Joypad.MODE_DPAD:
            if self.up: JOYP |= Joypad.UP
            if self.down: JOYP |= Joypad.DOWN
            if self.left: JOYP |= Joypad.LEFT
            if self.right: JOYP |= Joypad.RIGHT
        if JOYP & Joypad.MODE_BUTTONS:
            if self.b: JOYP |= Joypad.B
            if self.a: JOYP |= Joypad.A
            if self.start: JOYP |= Joypad.START
            if self.select: JOYP |= Joypad.SELECT
        self.cpu.ram[IO_JOYP] = ~JOYP

    def handle_inputs(self) -> bool:
        if self.headless:
            return True

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            elif event.type == pygame.KEYDOWN:
                self.need_interrupt = True
                if event.key == pygame.locals.K_ESCAPE:
                    return False
                elif event.key == pygame.locals.K_z:
                    self.b = True
                elif event.key == pygame.locals.K_x:
                    self.a = True
                elif event.key == pygame.locals.K_RETURN:
                    self.start = True
                elif event.key == pygame.locals.K_SPACE:
                    self.select = True
                elif event.key == pygame.locals.K_UP:
                    self.up = True
                elif event.key == pygame.locals.K_DOWN:
                    self.down = True
                elif event.key == pygame.locals.K_LEFT:
                    self.left = True
                elif event.key == pygame.locals.K_RIGHT:
                    self.right = True
                else:
                    self.need_interrupt = False
            elif event.type == pygame.KEYUP:
                if event.key == pygame.locals.K_z:
                    self.b = False
                elif event.key == pygame.locals.K_x:
                    self.a = False
                elif event.key == pygame.locals.K_RETURN:
                    self.start = False
                elif event.key == pygame.locals.K_SPACE:
                    self.select = False
                elif event.key == pygame.locals.K_UP:
                    self.up = False
                elif event.key == pygame.locals.K_DOWN:
                    self.down = False
                elif event.key == pygame.locals.K_LEFT:
                    self.left = False
                elif event.key == pygame.locals.K_RIGHT:
                    self.right = False
        return True
