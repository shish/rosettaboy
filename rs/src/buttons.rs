extern crate sdl2;
use crate::consts;
use crate::cpu;
use crate::ram;

use sdl2::event::Event;
use sdl2::keyboard::Keycode;

pub struct Buttons {
    up: bool,
    down: bool,
    left: bool,
    right: bool,
    a: bool,
    b: bool,
    start: bool,
    select: bool,
    cycle: u32,
}

impl Buttons {
    pub fn init() -> Result<Buttons, String> {
        Ok(Buttons {
            up: false,
            down: false,
            left: false,
            right: false,
            a: false,
            b: false,
            start: false,
            select: false,
            cycle: 0,
        })
    }

    /**
     * Turn OS keypresses into updates for the IO::JOYP byte
     */
    pub fn tick(&mut self, sdl: &sdl2::Sdl, ram: &mut ram::RAM, cpu: &mut cpu::CPU) -> bool {
        self.cycle += 1;

        let lx = self.cycle % 114;
        let ly = (self.cycle / 114) % 154;

        // handle SDL inputs every frame, but handle button register every CPU instruction
        self.update_buttons(ram, cpu);
        if lx == 20 && ly == 0 {
            return self.handle_inputs(sdl);
        } else {
            return true;
        }
    }

    /**
     * Once per frame, check the queue of input events from the OS,
     * store which buttons are pressed or not
     */
    fn handle_inputs(&mut self, sdl: &sdl2::Sdl) -> bool {
        for event in sdl.event_pump().unwrap().poll_iter() {
            // println!("Event: {:?}", event);
            match event {
                Event::Quit { .. } => return false,
                Event::KeyDown {
                    keycode: Some(Keycode::Escape),
                    ..
                } => return false,

                Event::KeyDown { keycode, .. } => match keycode {
                    Some(Keycode::Up) => self.up = true,
                    Some(Keycode::Down) => self.down = true,
                    Some(Keycode::Left) => self.left = true,
                    Some(Keycode::Right) => self.right = true,
                    Some(Keycode::Z) => self.b = true,
                    Some(Keycode::X) => self.a = true,
                    Some(Keycode::Return) => self.start = true,
                    Some(Keycode::Space) => self.select = true,
                    _ => {}
                },

                Event::KeyUp { keycode, .. } => match keycode {
                    Some(Keycode::Up) => self.up = false,
                    Some(Keycode::Down) => self.down = false,
                    Some(Keycode::Left) => self.left = false,
                    Some(Keycode::Right) => self.right = false,
                    Some(Keycode::Z) => self.b = false,
                    Some(Keycode::X) => self.a = false,
                    Some(Keycode::Return) => self.start = false,
                    Some(Keycode::Space) => self.select = false,
                    _ => {}
                },

                _ => {}
            }
        }

        true
    }

    /**
     * If `ram[JOYP].bit4 == 0`, then set `ram[JOYP].bit0-3` to up / down / left / right
     * If `ram[JOYP].bit5 == 0`, then set `ram[JOYP].bit0-3` to a / b / start / select
     *
     * Note that 0=pressed, 1=released
     */
    fn update_buttons(&mut self, ram: &mut ram::RAM, cpu: &mut cpu::CPU) {
        let mut joyp = ram.get(consts::IO::JOYP as u16);
        let prev_buttons = joyp & 0x0F;
        joyp |= 0x0F; // clear all buttons (0=pressed, 1=released)
        if joyp & consts::JoypSelect::Dpad as u8 == 0 {
            if self.up {
                joyp &= !(consts::JoypDpad::UP as u8);
            }
            if self.down {
                joyp &= !(consts::JoypDpad::DOWN as u8);
            }
            if self.left {
                joyp &= !(consts::JoypDpad::LEFT as u8);
            }
            if self.right {
                joyp &= !(consts::JoypDpad::RIGHT as u8);
            }
        }
        if joyp & consts::JoypSelect::Buttons as u8 == 0 {
            if self.b {
                joyp &= !(consts::JoypButton::B as u8);
            }
            if self.a {
                joyp &= !(consts::JoypButton::A as u8);
            }
            if self.start {
                joyp &= !(consts::JoypButton::START as u8);
            }
            if self.select {
                joyp &= !(consts::JoypButton::SELECT as u8);
            }
        }
        // if any button is pressed which wasn't pressed last time, interrupt
        // FIXME: do we also need to interrupt on button release?
        // FIXME: do we also need to interrupt even when neither Dpad nor Buttons are selected?
        if (joyp & 0x01 == 0 && prev_buttons & 0x01 == 0x01)
            || (joyp & 0x02 == 0 && prev_buttons & 0x02 == 0x02)
            || (joyp & 0x04 == 0 && prev_buttons & 0x04 == 0x04)
            || (joyp & 0x08 == 0 && prev_buttons & 0x08 == 0x08)
        {
            println!("Joyp interrupt: {:02X} {:02X}", joyp, prev_buttons);
            // FIXME: should interrupt() set stop=false? Then `stop`
            // can be private and we don't worry about it.
            cpu.stop = false;
            cpu.interrupt(ram, consts::Interrupt::JOYPAD);
        }
        ram.set(consts::IO::JOYP, joyp);
    }
}
