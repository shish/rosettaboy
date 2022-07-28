<?php

// FFS PHP
function exception_error_handler($errno, $errstr, $errfile, $errline)
{
    throw new ErrorException($errstr, $errno, 0, $errfile, $errline);
}
set_error_handler("exception_error_handler");

require "_sdl.php";
require "args.php";
require "gameboy.php";
require "errors.php";

$args = parse_args($argv);

try {
    $gameboy = new GameBoy($args);
    $gameboy->run();
} catch (EmuError $e) {
    print($e);
    exit($e->exit_code);
}
