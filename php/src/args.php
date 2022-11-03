<?php

function parse_args($argv)
{
    $rest_index = null;
    $opts = getopt("cgraHStf:p:h", ["debug-cpu", "debug-gpu", "debug-ram", "debug-apu", "headless", "silent", "turbo", "frames:", "profile:", "help"], $rest_index);
    $pos_args = array_slice($argv, $rest_index);
    if (array_key_exists('h', $opts) || array_key_exists('help', $opts) || count($pos_args) == 0) {
        print("PHP is awful. Getopt is awful. Read the docs to see flags.\n");
        exit(0);
    }
    //var_dump($opts);
    //var_dump($pos_args);
    return [
        "debug-cpu" => array_key_exists('c', $opts) || array_key_exists('debug-cpu', $opts),
        "debug-gpu" => array_key_exists('g', $opts) || array_key_exists('debug-gpu', $opts),
        "debug-ram" => array_key_exists('r', $opts) || array_key_exists('debug-ram', $opts),
        "debug-apu" => array_key_exists('a', $opts) || array_key_exists('debug-apu', $opts),
        "headless" => array_key_exists('H', $opts) || array_key_exists('headless', $opts),
        "silent" => array_key_exists('S', $opts) || array_key_exists('silent', $opts),
        "turbo" => array_key_exists('t', $opts) || array_key_exists('turbo', $opts),
        "frames" => array_key_exists('f', $opts) ? $opts['f'] : (array_key_exists('frames', $opts) ? $opts['frames'] : 0),
        "profile" => array_key_exists('p', $opts) ? $opts['p'] : (array_key_exists('profile', $opts) ? $opts['profile'] : 0),
        "rom" => $pos_args[0],
    ];
}
