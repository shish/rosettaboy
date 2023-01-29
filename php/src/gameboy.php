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

    public function __construct($args)
    {
        $this->cart = new Cart($args['rom']);
        $this->ram = new RAM($this->cart, $args['debug-ram']);
        $this->cpu = new CPU($this->ram, $args['debug-cpu']);
        $this->gpu = new GPU($this->cpu, $args['debug-gpu'], $args['headless']);
        $this->apu = new APU($args['silent'], $args['debug-apu']);
        $this->buttons = new Buttons($this->cpu, $args['headless']);
        $this->clock = new Clock($this->buttons, $args['frames'], $args['profile'], $args['turbo']);
    }

    public function run()
    {
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
