<?php
require "apu.php";
require "cart.php";
require "cpu.php";
require "gpu.php";
require "clock.php";
require "buttons.php";
require "ram.php";

$rest_index = null;
$opts = getopt("cgrHStp:", ["rom"], $rest_index);
$pos_args = array_slice($argv, $rest_index);
//var_dump($opts);
//var_dump($pos_args);

$cart = new Cart($pos_args[0]);
$ram = new RAM($cart, array_key_exists('r', $opts));
$cpu = new CPU($ram, array_key_exists('c', $opts));
$gpu = new GPU($cpu, array_key_exists('g', $opts), array_key_exists('H', $opts));
$apu = new APU(array_key_exists('S', $opts), array_key_exists('a', $opts));
$buttons = new Buttons($cpu, array_key_exists("H", $opts));
$clock = new Clock($buttons, array_key_exists('p', $opts) ? $opts['p'] : 0, array_key_exists('t', $opts));

while(true) {
    $cpu->tick();
    if(!$gpu->tick()) break;
    if(!$buttons->tick()) break;
    if(!$clock->tick()) break;
    if(!$apu->tick()) break;
}
