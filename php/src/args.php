<?php

function parse_args($argv)
{
    $rest_index = null;
    $opts = getopt("cgraHStp:", ["debug-cpu", "debug-gpu", "debug-ram", "debug-apu", "headless", "silent", "turbo", "profile:"], $rest_index);
    $pos_args = array_slice($argv, $rest_index);
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
        "profile" => array_key_exists('p', $opts) ? $opts['p'] : (array_key_exists('profile', $opts) ? $opts['profile'] : 0),
        "rom" => $pos_args[0],
    ];
}
