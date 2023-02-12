<?php

require "apu.php";
require "cart.php";
require "cpu.php";
require "gpu.php";
require "clock.php";
require "buttons.php";
require "ram.php";


class GameBoy
{
    private Cart $cart;
    private RAM $ram;
    private CPU $cpu;
    private GPU $gpu;
    private APU $apu;
    private Buttons $buttons;
    private Clock $clock;

    public function __construct(Args $args)
    {
        $this->cart = new Cart($args->rom);
        $this->ram = new RAM($this->cart, $args->debug_ram);
        $this->cpu = new CPU($this->ram, $args->debug_cpu);
        $this->gpu = new GPU($this->cpu, $args->debug_gpu, $args->headless);
        $this->apu = new APU($args->silent, $args->debug_apu);
        $this->buttons = new Buttons($this->cpu, $args->headless);
        $this->clock = new Clock($this->buttons, $args->frames, $args->profile, $args->turbo);
    }

    public function run()
    {
        // This is an infinite loop on purpose
        // @phpstan-ignore-next-line
        while (true) {
            $this->tick();
        }
    }

    public function tick()
    {
        $this->cpu->tick();
        $this->gpu->tick();
        $this->buttons->tick();
        $this->clock->tick();
        $this->apu->tick();
    }
}
