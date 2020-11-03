extern crate sdl2;
use crate::consts;
use crate::cpu;
use crate::ram;

use sdl2::controller::{Button, GameController};
use sdl2::event::Event;
use sdl2::keyboard::Keycode;

pub struct Buttons {
    sdl_context: sdl2::Sdl,
    _controller: Option<GameController>, // need to keep a reference to avoid deconstructor
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
    pub fn init(sdl_context: sdl2::Sdl) -> Result<Buttons, String> {
        let game_controller_subsystem = sdl_context.game_controller()?;

        let available = game_controller_subsystem.num_joysticks()?;

        // Iterate over all available joysticks and look for game controllers.
        let mut _controller = (0..available)
            .find_map(|id| {
                if !game_controller_subsystem.is_game_controller(id) {
                    return None;
                }

                match game_controller_subsystem.open(id) {
                    Ok(c) => Some(c),
                    Err(_) => None,
                }
            });

        Ok(Buttons {
            sdl_context,
            _controller,
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
    pub fn tick(&mut self, ram: &mut ram::RAM, cpu: &mut cpu::CPU) -> bool {
        self.cycle += 1;

        let lx = self.cycle % 114;
        let ly = (self.cycle / 114) % 154;

        // handle SDL inputs every frame, but handle button register every CPU instruction
        self.update_buttons(ram, cpu);
        if lx == 20 && ly == 0 {
            return self.handle_inputs();
        } else {
            return true;
        }
    }

    /**
     * Once per frame, check the queue of input events from the OS,
     * store which buttons are pressed or not
     */
    fn handle_inputs(&mut self) -> bool {
        for event in self.sdl_context.event_pump().unwrap().poll_iter() {
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

                Event::ControllerButtonDown { button, .. } => match button {
                    Button::DPadUp => self.up = true,
                    Button::DPadDown => self.down = true,
                    Button::DPadLeft => self.left = true,
                    Button::DPadRight => self.right = true,
                    Button::A => self.b = true,
                    Button::B => self.a = true,
                    Button::Start => self.start = true,
                    Button::Back => self.select = true,
                    _ => {}
                },
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

        true
    }

    /**
     * If `ram[JOYP].bit4 == 0`, then set `ram[JOYP].bit0-3` to up / down / left / right
     * If `ram[JOYP].bit5 == 0`, then set `ram[JOYP].bit0-3` to a / b / start / select
     *
     * Note that in memory, 0=pressed and 1=released - since this makes things
     * incredibly confusing, we invert the bits when reading the byte and invert
     * them back when writing.
     */
    fn update_buttons(&mut self, ram: &mut ram::RAM, cpu: &mut cpu::CPU) {
        let mut joyp = !consts::Joypad::from_bits_truncate(ram.get(consts::IO::JOYP as u16));
        let prev_joyp = joyp;
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
        // if any button is pressed which wasn't pressed last time, interrupt
        // FIXME: do we also need to interrupt on button release?
        // FIXME: do we also need to interrupt even when neither Dpad nor Buttons are selected?
        let pressed_now = joyp & consts::Joypad::BUTTON_BITS;
        let not_pressed_last_time = (!prev_joyp) & consts::Joypad::BUTTON_BITS;
        if pressed_now & not_pressed_last_time != consts::Joypad::empty() {
            println!("Joyp interrupt: {:02X} {:02X}", joyp, prev_joyp);
            // FIXME: should interrupt() set stop=false? Then `stop`
            // can be private and we don't worry about it.
            cpu.stop = false;
            cpu.interrupt(ram, consts::Interrupt::JOYPAD);
        }
        ram.set(consts::IO::JOYP, !joyp.bits());
    }
}
