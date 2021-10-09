import pygame
from .consts import Interrupt, Mem
from .cpu import CPU


class Joypad:
    MODE_BUTTONS = 1 << 5
    MODE_DPAD = 1 << 4
    DOWN = 1 << 3
    START = 1 << 3
    UP = 1 << 2
    SELECT = 1 << 2
    LEFT = 1 << 1
    B = 1 << 1
    RIGHT = 1 << 0
    A = 1 << 0


class Buttons:
    def __init__(self, cpu: CPU, headless=False) -> None:
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

    def update_buttons(self) -> None:
        JOYP = ~self.cpu.ram[Mem.JOYP]
        JOYP &= 0xF0
        if JOYP & Joypad.MODE_DPAD:
            if self.up:
                JOYP |= Joypad.UP
            if self.down:
                JOYP |= Joypad.DOWN
            if self.left:
                JOYP |= Joypad.LEFT
            if self.right:
                JOYP |= Joypad.RIGHT
        if JOYP & Joypad.MODE_BUTTONS:
            if self.b:
                JOYP |= Joypad.B
            if self.a:
                JOYP |= Joypad.A
            if self.start:
                JOYP |= Joypad.START
            if self.select:
                JOYP |= Joypad.SELECT
        self.cpu.ram[Mem.JOYP] = ~JOYP

    def handle_inputs(self) -> bool:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            elif event.type == pygame.KEYDOWN:
                self.need_interrupt = True
                if event.key == pygame.K_ESCAPE:
                    return False
                elif event.key == pygame.K_z:
                    self.b = True
                elif event.key == pygame.K_x:
                    self.a = True
                elif event.key == pygame.K_RETURN:
                    self.start = True
                elif event.key == pygame.K_SPACE:
                    self.select = True
                elif event.key == pygame.K_UP:
                    self.up = True
                elif event.key == pygame.K_DOWN:
                    self.down = True
                elif event.key == pygame.K_LEFT:
                    self.left = True
                elif event.key == pygame.K_RIGHT:
                    self.right = True
                else:
                    self.need_interrupt = False
            elif event.type == pygame.KEYUP:
                if event.key == pygame.K_z:
                    self.b = False
                elif event.key == pygame.K_x:
                    self.a = False
                elif event.key == pygame.K_RETURN:
                    self.start = False
                elif event.key == pygame.K_SPACE:
                    self.select = False
                elif event.key == pygame.K_UP:
                    self.up = False
                elif event.key == pygame.K_DOWN:
                    self.down = False
                elif event.key == pygame.K_LEFT:
                    self.left = False
                elif event.key == pygame.K_RIGHT:
                    self.right = False
        return True
