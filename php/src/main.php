<?php

// FFS PHP
function exception_error_handler($errno, $errstr, $errfile, $errline)
{
    throw new ErrorException($errstr, $errno, 0, $errfile, $errline);
}
set_error_handler("exception_error_handler");

if (!function_exists("SDL_Init")) {
    print("!!! WARNING !!!\nUsing fake SDL\n");
    require "_sdl.php";
}
require "args.php";
require "gameboy.php";
require "errors.php";

$args = parse_args($argv);

try {
    $gameboy = new GameBoy($args);
    $gameboy->run();
} catch (UnitTestFailed $e) {
    print($e);
    exit(2);
} catch (Quit $e) {
    exit(0);
} catch (ControlledExit $e) {
    print($e);
    exit(0);
} catch (GameException $e) {
    print($e);
    exit(3);
} catch (UserException $e) {
    print($e);
    exit(4);
}
