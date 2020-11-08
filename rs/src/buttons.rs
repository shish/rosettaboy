extern crate sdl2;
use crate::consts;
use crate::cpu;
use crate::ram;

use sdl2::controller::{Button, GameController};
use sdl2::event::Event;
use sdl2::keyboard::Keycode;

pub struct Buttons {
    sdl: sdl2::Sdl,
    _controller: Option<GameController>, // need to keep a reference to avoid deconstructor
    cycle: u32,
    need_interrupt: bool,
    up: bool,
    down: bool,
    left: bool,
    right: bool,
    a: bool,
    b: bool,
    start: bool,
    select: bool,
}

impl Buttons {
    pub fn init(sdl: sdl2::Sdl) -> Result<Buttons, String> {
        let game_controller_subsystem = sdl.game_controller()?;

        let available = game_controller_subsystem.num_joysticks()?;

        // Iterate over all available joysticks and look for game controllers.
        let mut _controller = (0..available).find_map(|id| {
            if !game_controller_subsystem.is_game_controller(id) {
                return None;
            }

            match game_controller_subsystem.open(id) {
                Ok(c) => Some(c),
                Err(_) => None,
            }
        });

        Ok(Buttons {
            sdl,
            _controller,
            cycle: 0,
            need_interrupt: false,
            up: false,
            down: false,
            left: false,
            right: false,
            a: false,
            b: false,
            start: false,
            select: false,
        })
    }

    /**
     * Turn OS keypresses into updates for the IO::JOYP byte.
     * Handle SDL inputs every frame, but handle button
     * register every CPU instruction
     */
    pub fn tick(&mut self, ram: &mut ram::RAM, cpu: &mut cpu::CPU) -> Result<(), String> {
        self.cycle += 1;

        self.update_buttons(ram);
        if self.need_interrupt {
            // if any button is pressed which wasn't pressed last time, interrupt
            // FIXME: do we also need to interrupt on button release?
            // FIXME: do we also need to interrupt even when neither Dpad nor Buttons are selected?
            cpu.stop = false;
            cpu.interrupt(ram, consts::Interrupt::JOYPAD);
            self.need_interrupt = false;
        }
        if self.cycle % 17556 == 20 {
            Ok(self.handle_inputs()?)
        } else {
            Ok(())
        }
    }

    /**
     * Once per frame, check the queue of input events from the OS,
     * store which buttons are pressed or not
     */
    fn handle_inputs(&mut self) -> Result<(), String> {
        for event in self.sdl.event_pump()?.poll_iter() {
            // println!("Event: {:?}", event);
            match event {
                Event::Quit { .. } => return Err("Quit".to_string()),
                Event::KeyDown {
                    keycode: Some(Keycode::Escape),
                    ..
                } => return Err("Quit".to_string()),

                Event::KeyDown {
                    keycode: Some(keycode),
                    ..
                } => {
                    self.need_interrupt = true;
                    match keycode {
                        Keycode::Up => self.up = true,
                        Keycode::Down => self.down = true,
                        Keycode::Left => self.left = true,
                        Keycode::Right => self.right = true,
                        Keycode::Z => self.b = true,
                        Keycode::X => self.a = true,
                        Keycode::Return => self.start = true,
                        Keycode::Space => self.select = true,
                        _ => self.need_interrupt = false,
                    }
                }
                Event::KeyUp {
                    keycode: Some(keycode),
                    ..
                } => match keycode {
                    Keycode::Up => self.up = false,
                    Keycode::Down => self.down = false,
                    Keycode::Left => self.left = false,
                    Keycode::Right => self.right = false,
                    Keycode::Z => self.b = false,
                    Keycode::X => self.a = false,
                    Keycode::Return => self.start = false,
                    Keycode::Space => self.select = false,
                    _ => {}
                },

                Event::ControllerButtonDown { button, .. } => {
                    self.need_interrupt = true;
                    match button {
                        Button::DPadUp => self.up = true,
                        Button::DPadDown => self.down = true,
                        Button::DPadLeft => self.left = true,
                        Button::DPadRight => self.right = true,
                        Button::A => self.b = true,
                        Button::B => self.a = true,
                        Button::Start => self.start = true,
                        Button::Back => self.select = true,
                        _ => self.need_interrupt = false,
                    }
                }
                Event::ControllerButtonUp { button, .. } => match button {
                    Button::DPadUp => self.up = false,
                    Button::DPadDown => self.down = false,
                    Button::DPadLeft => self.left = false,
                    Button::DPadRight => self.right = false,
                    Button::A => self.b = false,
                    Button::B => self.a = false,
                    Button::Start => self.start = false,
                    Button::Back => self.select = false,
                    _ => {}
                },
                _ => {}
            }
        }

        Ok(())
    }

    /**
     * If `ram[JOYP].bit4 == 0`, then set `ram[JOYP].bit0-3` to up / down / left / right
     * If `ram[JOYP].bit5 == 0`, then set `ram[JOYP].bit0-3` to a / b / start / select
     *
     * Note that in memory, 0=pressed and 1=released - since this makes things
     * incredibly confusing, we invert the bits when reading the byte and invert
     * them back when writing.
     */
    #[inline(always)]
    fn update_buttons(&mut self, ram: &mut ram::RAM) {
        let mut joyp = !consts::Joypad::from_bits_truncate(ram.get(consts::IO::JOYP as u16));
        joyp.remove(consts::Joypad::BUTTON_BITS);
        if joyp.contains(consts::Joypad::MODE_DPAD) {
            if self.up {
                joyp.insert(consts::Joypad::UP);
            }
            if self.down {
                joyp.insert(consts::Joypad::DOWN);
            }
            if self.left {
                joyp.insert(consts::Joypad::LEFT);
            }
            if self.right {
                joyp.insert(consts::Joypad::RIGHT);
            }
        }
        if joyp.contains(consts::Joypad::MODE_BUTTONS) {
            if self.b {
                joyp.insert(consts::Joypad::B);
            }
            if self.a {
                joyp.insert(consts::Joypad::A);
            }
            if self.start {
                joyp.insert(consts::Joypad::START);
            }
            if self.select {
                joyp.insert(consts::Joypad::SELECT);
            }
        }
        ram.set(consts::IO::JOYP, !joyp.bits());
    }
}
