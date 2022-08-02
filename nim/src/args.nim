import std/os

import argparse

type
    Args* = object
        rom*: string
        profile*: int
        headless*, silent*: bool
        turbo*, debug_cpu*, debug_apu*, debug_gpu*, debug_ram*: bool

proc parse_args*(args: seq[string]): Args =
    var p = newParser("rosettaboy-nim"):
        flag("-H", "--headless")
        flag("-S", "--silent")
        flag("-c", "--debug-cpu")
        flag("-g", "--debug-gpu")
        flag("-r", "--debug-ram")
        flag("-a", "--debug-apu")
        flag("-t", "--turbo")
        option("-p", "--profile", default=some("0"), help="Exit after N frames")
        arg("rom")

    try:
        var opts = p.parse(args)
        return  Args(
            rom: opts.rom,
            headless: opts.headless,
            silent: false,
            debug_cpu: false,
            debug_gpu: false,
            debug_apu: false,
            debug_ram: false,
            profile: parseInt(opts.profile),
            turbo: false,
        )
    except ShortCircuit as e:
        if e.flag == "argparse_help":
            echo p.help
            quit(1)
