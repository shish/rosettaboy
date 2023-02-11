import { Cart } from "./cart";
import { RAM } from "./ram";
import { CPU } from "./cpu";
import { GPU } from "./gpu";
import { APU } from "./apu";
import { Buttons } from "./buttons";
import { Clock } from "./clock";

export class GameBoy {
    cart: Cart;
    ram: RAM;
    cpu: CPU;
    gpu: GPU;
    apu: APU;
    buttons: Buttons;
    clock: Clock;

    constructor(args: any) {
        // let sdl = sdl2::init().map_err(anyhow::Error::msg)?;
        let sdl = null;

        this.cart = new Cart(args.rom);
        this.ram = new RAM(this.cart, args.debugRam);
        this.cpu = new CPU(this.ram, args.debugCpu);
        this.gpu = new GPU(
            this.cpu,
            this.cart.name,
            args.headless,
            args.debugGpu,
        );
        this.apu = new APU(this.ram, args.silent, args.debugApu);
        this.buttons = new Buttons(this.cpu, this.gpu.hw_window);
        this.clock = new Clock(
            this.buttons,
            args.frames,
            args.profile,
            args.turbo,
        );
    }

    async run() {
        while (true) {
            await this.tick();
        }
    }

    async tick() {
        this.cpu.tick();
        this.gpu.tick();
        this.buttons.tick();
        await this.clock.tick();
        this.apu.tick();
    }
}
