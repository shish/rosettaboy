use anyhow::Result;

use crate::apu;
use crate::args;
use crate::buttons;
use crate::cart;
use crate::clock;
use crate::cpu;
use crate::gpu;
use crate::ram;

pub struct GameBoy<'a> {
    ram: ram::RAM,
    cpu: cpu::CPU,
    gpu: gpu::GPU<'a>,
    apu: apu::APU,
    buttons: buttons::Buttons,
    clock: clock::Clock,
}

impl<'a> GameBoy<'a> {
    #[inline(never)]
    pub fn new(args: args::Args) -> Result<GameBoy<'a>> {
        let sdl = sdl2::init().map_err(anyhow::Error::msg)?;

        let cart = cart::Cart::new(args.rom.as_str())?;
        let cart_name = cart.name.clone();
        let ram = ram::RAM::new(cart)?;
        let cpu = cpu::CPU::new(args.debug_cpu);
        let gpu = gpu::GPU::new(&sdl, cart_name, args.headless, args.debug_gpu)?;
        let apu = apu::APU::new(&sdl, args.silent, args.debug_apu)?;
        let buttons = buttons::Buttons::new(sdl, args.headless)?;
        let clock = clock::Clock::new(args.profile, args.turbo);

        Ok(GameBoy {
            ram,
            cpu,
            gpu,
            apu,
            buttons,
            clock,
        })
    }

    #[inline(never)]
    pub fn run(&mut self) -> Result<()> {
        loop {
            self.tick()?;
        }
    }

    #[inline(always)]
    pub fn tick(&mut self) -> Result<()> {
        self.cpu.tick(&mut self.ram)?;
        self.gpu.tick(&mut self.ram, &mut self.cpu)?;
        self.buttons.tick(&mut self.ram, &mut self.cpu)?;
        self.clock.tick(&self.buttons)?;
        self.apu.tick(&mut self.ram);

        Ok(())
    }
}
