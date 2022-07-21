import sdl2
import ctypes
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
        self.turbo = False

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
        if self.headless:
            return True

        event = sdl2.SDL_Event()
        while sdl2.SDL_PollEvent(ctypes.byref(event)) != 0:
            if event.type == sdl2.SDL_QUIT:
                return False
            elif event.type == sdl2.SDL_KEYDOWN:
                key = event.key.keysym.sym
                self.need_interrupt = True
                if key == sdl2.SDLK_ESCAPE:
                    return False
                elif key == sdl2.SDLK_LSHIFT:
                    self.turbo = True
                    self.need_interrupt = False
                elif key == sdl2.SDLK_z:
                    self.b = True
                elif key == sdl2.SDLK_x:
                    self.a = True
                elif key == sdl2.SDLK_RETURN:
                    self.start = True
                elif key == sdl2.SDLK_SPACE:
                    self.select = True
                elif key == sdl2.SDLK_UP:
                    self.up = True
                elif key == sdl2.SDLK_DOWN:
                    self.down = True
                elif key == sdl2.SDLK_LEFT:
                    self.left = True
                elif key == sdl2.SDLK_RIGHT:
                    self.right = True
                else:
                    self.need_interrupt = False
            elif event.type == sdl2.SDL_KEYUP:
                key = event.key.keysym.sym
                if key == sdl2.SDLK_LSHIFT:
                    self.turbo = False
                elif key == sdl2.SDLK_z:
                    self.b = False
                elif key == sdl2.SDLK_x:
                    self.a = False
                elif key == sdl2.SDLK_RETURN:
                    self.start = False
                elif key == sdl2.SDLK_SPACE:
                    self.select = False
                elif key == sdl2.SDLK_UP:
                    self.up = False
                elif key == sdl2.SDLK_DOWN:
                    self.down = False
                elif key == sdl2.SDLK_LEFT:
                    self.left = False
                elif key == sdl2.SDLK_RIGHT:
                    self.right = False
        return True
