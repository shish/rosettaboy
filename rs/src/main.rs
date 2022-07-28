#![allow(clippy::needless_return)]
#![allow(clippy::identity_op)]
#![allow(clippy::upper_case_acronyms)]
#![allow(clippy::many_single_char_names)]

use anyhow::{anyhow, Result};
use clap::Parser;
extern crate sdl2;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[macro_use]
extern crate bitflags;

mod args;
mod apu;
mod buttons;
mod cart;
mod clock;
mod consts;
mod cpu;
mod errors;
mod gpu;
mod ram;


struct Gameboy<'a> {
    ram: ram::RAM,
    cpu: cpu::CPU,
    gpu: gpu::GPU<'a>,
    apu: apu::APU,
    buttons: buttons::Buttons,
    clock: clock::Clock,
}
impl<'a> Gameboy<'a> {
    #[inline(never)]
    fn new(args: args::Args) -> Result<Gameboy<'a>> {
        let sdl = sdl2::init().map_err(anyhow::Error::msg)?;

        let cart = cart::Cart::new(args.rom.as_str())?;
        let cart_name = cart.name.clone();
        let ram = ram::RAM::new(cart);
        let cpu = cpu::CPU::new(args.debug_cpu);
        let gpu = gpu::GPU::new(&sdl, cart_name, args.headless, args.debug_gpu)?;
        let apu = apu::APU::new(&sdl, args.silent, args.debug_apu)?;
        let buttons = buttons::Buttons::new(sdl, args.headless)?;
        let clock = clock::Clock::new(args.profile, args.turbo);

        Ok(Gameboy {
            ram,
            cpu,
            gpu,
            apu,
            buttons,
            clock,
        })
    }

    #[inline(never)]
    fn run(&mut self) -> Result<()> {
        loop {
            self.cpu.tick(&mut self.ram)?;
            self.gpu.tick(&mut self.ram, &mut self.cpu)?;
            self.buttons.tick(&mut self.ram, &mut self.cpu)?;
            self.clock.tick(&self.buttons)?;
            self.apu.tick(&mut self.ram);
        }
    }
}

fn configure_logging(args: &args::Args) {
    let mut levels = "rosettaboy_rs=warn".to_string();
    if args.debug_apu {
        levels.push_str(",rosettaboy_rs::apu=debug");
    }
    if args.debug_cpu {
        levels.push_str(",rosettaboy_rs::cpu=debug");
    }
    if args.debug_gpu {
        levels.push_str(",rosettaboy_rs::gpu=debug");
    }
    if args.debug_ram {
        levels.push_str(",rosettaboy_rs::ram=debug");
    }
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| levels.into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();
}

fn main() -> Result<()> {
    let args = args::Args::parse();
    configure_logging(&args);
    match Gameboy::new(args)?.run() {
        Ok(_) => Err(anyhow!("Main loop exited with no error??")),
        Err(e) => {
            if let Some(emu_error) = e.downcast_ref::<errors::EmuError>() {
                println!("{}", emu_error);
                std::process::exit(emu_error.exit_code());
            }
            Err(e)
        }
    }
}
