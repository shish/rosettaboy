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

mod apu;
mod buttons;
mod cart;
mod clock;
mod consts;
mod cpu;
mod gpu;
mod ram;

/// RosettaBoy - Rust
#[derive(Parser)]
#[clap(about, author, version)]
struct Args {
    /// Path to a .gb file
    #[clap(default_value = "game.gb")]
    rom: String,

    /// Disable GUI
    #[clap(short = 'H', long)]
    headless: bool,

    /// Disable Sound
    #[clap(short = 'S', long)]
    silent: bool,

    /// Debug CPU
    #[clap(short = 'c', long)]
    debug_cpu: bool,

    /// Debug GPU
    #[clap(short = 'g', long)]
    debug_gpu: bool,

    /// Debug APU
    #[clap(short = 'a', long)]
    debug_apu: bool,

    /// Debug RAM
    #[clap(short = 'r', long)]
    debug_ram: bool,

    /// Exit after N frames
    #[clap(short, long, default_value = "0")]
    profile: u32,

    /// No sleep()
    #[clap(short, long)]
    turbo: bool,
}

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
    fn new(args: Args) -> Result<Gameboy<'a>> {
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

fn configure_logging(args: &Args) {
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
    let args = Args::parse();
    configure_logging(&args);
    match Gameboy::new(args)?.run() {
        Ok(_) => Err(anyhow!("Main loop exited with no error??")),
        Err(e) => {
            if let Some(emu_error) = e.downcast_ref::<consts::EmuError>() {
                match emu_error {
                    consts::EmuError::Quit => {
                        std::process::exit(0);
                    }
                    consts::EmuError::Timeout(frames, duration) => {
                        println!(
                            "Emulated {} frames in {:.2}s ({:.2}fps)",
                            frames,
                            duration,
                            *frames as f32 / duration
                        );
                        std::process::exit(0);
                    }
                    consts::EmuError::UnitTestPassed => {
                        println!("Unit test passed");
                        std::process::exit(0);
                    }
                    consts::EmuError::UnitTestFailed => {
                        println!("Unit test passed");
                        std::process::exit(2);
                    }
                    e => {
                        println!("Error: {}", e);
                        std::process::exit(1);
                    }
                }
            }
            Err(e)
        }
    }
}
