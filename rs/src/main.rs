#![allow(clippy::needless_return)]
#![allow(clippy::identity_op)]
#![allow(clippy::upper_case_acronyms)]
#![allow(clippy::many_single_char_names)]

use anyhow::Result;
use structopt::StructOpt;
extern crate sdl2;

#[macro_use]
extern crate bitflags;
#[macro_use]
extern crate packed_struct_codegen;

mod apu;
mod buttons;
mod cart;
mod clock;
mod consts;
mod cpu;
mod gpu;
mod ram;

#[derive(StructOpt)]
#[structopt(about = "RosettaBoy - Rust")]
struct Args {
    /// Path to a .gb file
    #[structopt(default_value = "game.gb")]
    rom: String,

    /// Disable GUI
    #[structopt(short = "H", long)]
    headless: bool,

    /// Disable Sound
    #[structopt(short = "S", long)]
    silent: bool,

    /// Debug CPU
    #[structopt(short = "c", long)]
    debug_cpu: bool,

    /// Debug GPU
    #[structopt(short = "g", long)]
    debug_gpu: bool,

    /// Debug APU
    #[structopt(short = "a", long)]
    debug_apu: bool,

    /// Debug RAM
    #[structopt(short = "r", long)]
    debug_ram: bool,

    /// Exit after N frames
    #[structopt(short, long, default_value = "0")]
    profile: u32,

    /// No sleep()
    #[structopt(short, long)]
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
    fn init(args: Args) -> Result<Gameboy<'a>> {
        let sdl = sdl2::init().map_err(anyhow::Error::msg)?;

        let cart = cart::Cart::init(args.rom.as_str())?;
        let cart_name = cart.name.clone();
        let ram = ram::RAM::init(cart, args.debug_ram);
        let cpu = cpu::CPU::init(args.debug_cpu);
        let gpu = gpu::GPU::init(&sdl, cart_name.as_str(), args.headless, args.debug_gpu)?;
        let apu = apu::APU::init(&sdl, args.silent, args.debug_apu)?;
        let buttons = buttons::Buttons::init(sdl, args.headless)?;
        let clock = clock::Clock::init(args.profile, args.turbo);

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
            self.clock.tick()?;
            self.apu.tick(&mut self.ram);
        }
    }
}

fn main() -> Result<()> {
    Gameboy::init(Args::from_args())?.run()?;

    // because debug ROMs print to stdout without newline
    println!();

    Ok(())
}
