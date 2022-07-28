<?php

// FFS PHP
function exception_error_handler($errno, $errstr, $errfile, $errline)
{
    throw new ErrorException($errstr, $errno, 0, $errfile, $errline);
}
set_error_handler("exception_error_handler");

require "_sdl.php";
require "args.php";
require "apu.php";
require "cart.php";
require "cpu.php";
require "errors.php";
require "gpu.php";
require "clock.php";
require "buttons.php";
require "ram.php";

$args = parse_args($argv);
$cart = new Cart($args['rom']);
$ram = new RAM($cart, $args['debug-ram']);
$cpu = new CPU($ram, $args['debug-cpu']);
$gpu = new GPU($cpu, $args['debug-gpu'], $args['headless']);
$apu = new APU($args['silent'], $args['debug-apu']);
$buttons = new Buttons($cpu, $args['headless']);
$clock = new Clock($buttons, $args['profile'], $args['turbo']);

try {
    while (true) {
        $cpu->tick();
        $gpu->tick();
        $buttons->tick();
        $clock->tick();
        $apu->tick();
    }
} catch (EmuError $e) {
    print($e);
    exit($e->exit_code);
}
