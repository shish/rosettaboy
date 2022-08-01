import std/bitops

import sdl2

import errors
import consts
import cpu
import ram

type
    Buttons* = object
        cpu: cpu.CPU
        ram: ram.RAM
        headless: bool
        turbo*: bool
        cycle: int
        need_interrupt: bool
        up: bool
        down: bool
        left: bool
        right: bool
        a: bool
        b: bool
        start: bool
        select: bool

proc create*(cpu: cpu.CPU, ram: ram.RAM, headless: bool): Buttons =
    return Buttons(
        cpu: cpu,
        ram: ram,
        headless: headless,
    )

#[
If `ram[JOYP].bit4 == 0`, then set `ram[JOYP].bit0-3` to up / down / left / right
If `ram[JOYP].bit5 == 0`, then set `ram[JOYP].bit0-3` to a / b / start / select

Note that in memory, 0=pressed and 1=released - since this makes things
incredibly confusing, we invert the bits when reading the byte and invert
them back when writing.
]#
proc update_buttons(self: var Buttons) =
    var joyp = bitops.bitnot(self.ram.get(consts.Mem_JOYP))
#[
    joyp.remove(Joypad::BUTTON_BITS);
    if joyp.contains(Joypad::MODE_DPAD):
        if self.up:
            joyp.insert(Joypad::UP);
        if self.down:
            joyp.insert(Joypad::DOWN);
        if self.left:
            joyp.insert(Joypad::LEFT);
        if self.right:
            joyp.insert(Joypad::RIGHT);
    if joyp.contains(Joypad::MODE_BUTTONS):
        if self.b:
            joyp.insert(Joypad::B);
        if self.a:
            joyp.insert(Joypad::A);
        if self.start:
            joyp.insert(Joypad::START);
        if self.select:
            joyp.insert(Joypad::SELECT);
]#
    self.ram.set(consts.Mem_JOYP, bitops.bitnot(joyp));


#[
Once per frame, check the queue of input events from the OS,
store which buttons are pressed or not
]#
proc handle_inputs(self: var Buttons) =
    if self.headless:
        return

    var event = sdl2.defaultEvent
    while pollEvent(event):
        case event.kind:
            of QuitEvent:
                raise errors.Quit.newException("FIXME quit")
            of KeyDown:
                let key = event.key()
                self.need_interrupt = true;
                case key.keysym.sym:
                    of K_ESCAPE:
                        raise errors.Quit.newException("FIXME quit")
                    of K_LSHIFT:
                        self.turbo = true
                        self.need_interrupt = false
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
                        self.need_interrupt = false
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
                self.need_interrupt = true;
                case event.button:
                    Button::DPadUp: self.up = true,
                    Button::DPadDown: self.down = true,
                    Button::DPadLeft: self.left = true,
                    Button::DPadRight: self.right = true,
                    Button::A: self.b = true,
                    Button::B: self.a = true,
                    Button::Start: self.start = true,
                    Button::Back: self.select = true,
                    else: self.need_interrupt = false,
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


proc tick*(self: var Buttons) =
    self.cycle += 1
    self.update_buttons()
    if self.need_interrupt:
        self.cpu.stop = false
        self.cpu.interrupt(consts.Interrupt_JOYPAD)
        self.need_interrupt = false
    if self.cycle mod 17556 == 20:
        self.handle_inputs()
