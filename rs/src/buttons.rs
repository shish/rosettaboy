extern crate sdl2;
use crate::consts::*;
use crate::cpu;
use crate::ram;
use anyhow::{anyhow, Result};

use sdl2::controller::{Button, GameController};
use sdl2::event::Event;
use sdl2::keyboard::Keycode;

bitflags! {
    pub struct Joypad: u8 {
        const MODE_BUTTONS = 1<<5;
        const MODE_DPAD = 1<<4;
        const DOWN = 1<<3;
        const START = 1<<3;
        const UP = 1<<2;
        const SELECT = 1<<2;
        const LEFT = 1<<1;
        const B = 1<<1;
        const RIGHT = 1<<0;
        const A = 1<<0;
        const BUTTON_BITS = 0b00001111;
    }
}

pub struct Buttons {
    sdl: sdl2::Sdl,
    _controller: Option<GameController>, // need to keep a reference to avoid deconstructor
    headless: bool,
    cycle: u32,
    need_interrupt: bool,
    pub turbo: bool,
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
    pub fn new(sdl: sdl2::Sdl, headless: bool) -> Result<Buttons> {
        let game_controller_subsystem = sdl.game_controller().map_err(anyhow::Error::msg)?;

        let available = game_controller_subsystem
            .num_joysticks()
            .map_err(anyhow::Error::msg)?;

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
            headless,
            cycle: 0,
            need_interrupt: false,
            turbo: false,
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
     * Turn OS keypresses into updates for the Mem::JOYP byte.
     * Handle SDL inputs every frame, but handle button
     * register every CPU instruction
     */
    pub fn tick(&mut self, ram: &mut ram::RAM, cpu: &mut cpu::CPU) -> Result<()> {
        self.cycle += 1;
        self.update_buttons(ram);
        if self.need_interrupt {
            cpu.stop = false;
            cpu.interrupt(ram, Interrupt::JOYPAD);
            self.need_interrupt = false;
        }
        if self.cycle % 17556 == 20 {
            Ok(self.handle_inputs()?)
        } else {
            Ok(())
        }
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
        let mut joyp = !Joypad::from_bits_truncate(ram.get(Mem::JOYP));
        joyp.remove(Joypad::BUTTON_BITS);
        if joyp.contains(Joypad::MODE_DPAD) {
            if self.up {
                joyp.insert(Joypad::UP);
            }
            if self.down {
                joyp.insert(Joypad::DOWN);
            }
            if self.left {
                joyp.insert(Joypad::LEFT);
            }
            if self.right {
                joyp.insert(Joypad::RIGHT);
            }
        }
        if joyp.contains(Joypad::MODE_BUTTONS) {
            if self.b {
                joyp.insert(Joypad::B);
            }
            if self.a {
                joyp.insert(Joypad::A);
            }
            if self.start {
                joyp.insert(Joypad::START);
            }
            if self.select {
                joyp.insert(Joypad::SELECT);
            }
        }
        ram.set(Mem::JOYP, !joyp.bits());
    }

    /**
     * Once per frame, check the queue of input events from the OS,
     * store which buttons are pressed or not
     */
    fn handle_inputs(&mut self) -> Result<()> {
        if self.headless {
            return Ok(());
        }

        for event in self
            .sdl
            .event_pump()
            .map_err(anyhow::Error::msg)?
            .poll_iter()
        {
            tracing::debug!("Event: {:?}", event);
            match event {
                Event::Quit { .. } => return Err(anyhow!("Quit")),

                Event::KeyDown {
                    keycode: Some(keycode),
                    ..
                } => {
                    self.need_interrupt = true;
                    match keycode {
                        Keycode::Escape => return Err(anyhow!("Quit")),
                        Keycode::LShift => {
                            self.turbo = true;
                            self.need_interrupt = false
                        }
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
                    Keycode::LShift => self.turbo = false,
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
}
