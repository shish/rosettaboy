import std/bitops

import sdl2

import errors
import consts
import cpu
import ram

type
    Buttons* = ref object
        cpu: cpu.CPU
        ram: ram.RAM
        turbo*: bool
        cycle: int
        up: bool
        down: bool
        left: bool
        right: bool
        a: bool
        b: bool
        start: bool
        select: bool

const JOYPAD_MODE_BUTTONS = 1 shl 5
const JOYPAD_MODE_DPAD = 1 shl 4
const JOYPAD_DOWN = 1 shl 3
const JOYPAD_START = 1 shl 3
const JOYPAD_UP = 1 shl 2
const JOYPAD_SELECT = 1 shl 2
const JOYPAD_LEFT = 1 shl 1
const JOYPAD_B = 1 shl 1
const JOYPAD_RIGHT = 1 shl 0
const JOYPAD_A = 1 shl 0
# const JOYPAD_BUTTON_BITS = 0b00001111

proc create*(cpu: cpu.CPU, ram: ram.RAM, headless: bool): Buttons =
    if not headless:
        discard sdl2.init(sdl2.INIT_GAMECONTROLLER)
    return Buttons(
        cpu: cpu,
        ram: ram,
    )

#[
If `ram[JOYP].bit4 == 0`, then set `ram[JOYP].bit0-3` to up / down / left / right
If `ram[JOYP].bit5 == 0`, then set `ram[JOYP].bit0-3` to a / b / start / select

Note that in memory, 0=pressed and 1=released - since this makes things
incredibly confusing, we invert the bits when reading the byte and invert
them back when writing.
]#
proc updateButtons(self: Buttons) =
    var joyp = bitops.bitnot(self.ram.get(consts.Mem_JOYP))
    joyp = bitops.bitand(joyp, 0x30)
    if bitops.bitand(joyp, JOYPAD_MODE_DPAD) != 0:
        if self.up:
            joyp = bitops.bitor(joyp, JOYPAD_UP)
        if self.down:
            joyp = bitops.bitor(joyp, JOYPAD_DOWN)
        if self.left:
            joyp = bitops.bitor(joyp, JOYPAD_LEFT)
        if self.right:
            joyp = bitops.bitor(joyp, JOYPAD_RIGHT)
    if bitops.bitand(joyp, JOYPAD_MODE_BUTTONS) != 0:
        if self.b:
            joyp = bitops.bitor(joyp, JOYPAD_B)
        if self.a:
            joyp = bitops.bitor(joyp, JOYPAD_A)
        if self.start:
            joyp = bitops.bitor(joyp, JOYPAD_START)
        if self.select:
            joyp = bitops.bitor(joyp, JOYPAD_SELECT)
    self.ram.set(consts.Mem_JOYP, bitops.bitand(bitops.bitnot(joyp), 0x3F))


#[
Once per frame, check the queue of input events from the OS,
store which buttons are pressed or not
]#
proc handleInputs(self: Buttons): bool =
    var needInterrupt = false;

    var event = sdl2.defaultEvent
    while pollEvent(event):
        case event.kind:
            of QuitEvent:
                raise errors.Quit.newException("FIXME quit")
            of KeyDown:
                let key = event.key()
                needInterrupt = true;
                case key.keysym.sym:
                    of K_ESCAPE:
                        raise errors.Quit.newException("FIXME quit")
                    of K_LSHIFT:
                        self.turbo = true
                        needInterrupt = false
                        break
                    of K_UP:
                        self.up = true
                        break
                    of K_DOWN:
                        self.down = true
                        break
                    of K_LEFT:
                        self.left = true
                        break
                    of K_RIGHT:
                        self.right = true
                        break
                    of K_Z:
                        self.b = true
                        break
                    of K_X:
                        self.a = true
                        break
                    of K_RETURN:
                        self.start = true
                        break
                    of K_SPACE:
                        self.select = true
                        break
                    else:
                        needInterrupt = false
                        break
            of KeyUp:
                let key = event.key()
                case key.keysym.sym:
                    of K_LSHIFT:
                        self.turbo = false; break;
                    of K_UP:
                        self.up = false; break;
                    of K_DOWN:
                        self.down = false; break;
                    of K_LEFT:
                        self.left = false; break;
                    of K_RIGHT:
                        self.right = false; break;
                    of K_Z:
                        self.b = false; break;
                    of K_X:
                        self.a = false; break;
                    of K_RETURN:
                        self.start = false; break;
                    of K_SPACE:
                        self.select = false; break;
                    else:
                        break;
            else:
                break;
            # FIXME: controller support
            #[
            of ControllerButtonDown:
                need_interrupt = true;
                case event.button:
                    Button::DPadUp: self.up = true,
                    Button::DPadDown: self.down = true,
                    Button::DPadLeft: self.left = true,
                    Button::DPadRight: self.right = true,
                    Button::A: self.b = true,
                    Button::B: self.a = true,
                    Button::Start: self.start = true,
                    Button::Back: self.select = true,
                    else: need_interrupt = false,
                of ControllerButtonUp:
                    case event.button:
                        Button::DPadUp: self.up = false,
                        Button::DPadDown: self.down = false,
                        Button::DPadLeft: self.left = false,
                        Button::DPadRight: self.right = false,
                        Button::A: self.b = false,
                        Button::B: self.a = false,
                        Button::Start: self.start = false,
                        Button::Back: self.select = false,
                    ]#

    return needInterrupt


proc tick*(self: Buttons) =
    self.cycle += 1
    self.updateButtons()
    if self.cycle mod 17556 == 20:
        if self.handleInputs():
            self.cpu.stop = false
            self.cpu.interrupt(consts.Interrupt_JOYPAD)
