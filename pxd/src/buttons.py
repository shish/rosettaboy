import cython

if not cython.compiled:
    import sdl2

import ctypes
import typing as t
from .errors import Quit

if cython.compiled:
    from cython.cimports.cpython.mem import PyMem_Malloc, PyMem_Free
else:
    from .cpu import CPU
    from .consts import Interrupt, Mem, u8, booli


class _Joypad:
    def __init__(self):
        self.MODE_BUTTONS: cython.int = 1 << 5
        self.MODE_DPAD: cython.int = 1 << 4
        self.DOWN: cython.int = 1 << 3
        self.START: cython.int = 1 << 3
        self.UP: cython.int = 1 << 2
        self.SELECT: cython.int = 1 << 2
        self.LEFT: cython.int = 1 << 1
        self.B: cython.int = 1 << 1
        self.RIGHT: cython.int = 1 << 0
        self.A: cython.int = 1 << 0


Joypad = _Joypad()


class Buttons:
    def __init__(self, cpu: CPU, headless: bool) -> None:
        if not headless:
            sdl2.SDL_InitSubSystem(sdl2.SDL_INIT_GAMECONTROLLER)

        self.cpu = cpu

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

    def tick(self) -> None:
        self.cycle += 1
        self.update_buttons()
        if self.cycle % 17556 == 20:
            if self.handle_inputs():
                self.cpu.stop = False
                self.cpu.interrupt(Interrupt.JOYPAD)

    def update_buttons(self) -> None:
        JOYP: u8
        JOYP = ~self.cpu.ram.get(Mem.JOYP)
        JOYP &= 0x30
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

        self.cpu.ram.set(Mem.JOYP, ~JOYP & 0x3F)

    def handle_inputs(self) -> bool:
        need_interrupt = False
        key: cython.int

        if cython.compiled:
            event: cython.pointer(sdl2.SDL_Event)
            event = cython.cast(
                cython.pointer(sdl2.SDL_Event),
                PyMem_Malloc(cython.sizeof(sdl2.SDL_Event)),
            )
        else:
            event = sdl2.SDL_Event()
        while (
            sdl2.SDL_PollEvent(event if cython.compiled else ctypes.byref(event)) != 0
        ):
            if event.type == sdl2.SDL_QUIT:
                raise Quit()
            elif event.type == sdl2.SDL_KEYDOWN:
                key = event.key.keysym.sym
                need_interrupt = True
                if key == sdl2.SDLK_ESCAPE:
                    raise Quit()
                elif key == sdl2.SDLK_LSHIFT:
                    self.turbo = True
                    need_interrupt = False
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
                    need_interrupt = False
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

        if cython.compiled:
            PyMem_Free(event)

        return need_interrupt
