import std/parseopt
import strutils

type
    Args* = object
        rom*: string
        profile*: int
        headless*, silent*: bool
        turbo*, debug_cpu*, debug_apu*, debug_gpu*, debug_ram*: bool

proc parse_args*(): Args =
    var args = Args(
        rom: "",
        headless: false,
        silent: false,
        debug_cpu: false,
        debug_gpu: false,
        debug_apu: false,
        debug_ram: false,
        profile: 0,
        turbo: false,
    )

    # FIXME: this feels awful on so many levels?
    # FIXME: short options
    # FIXME: --help
    # FIXME: options without "="
    # FIXME: get options from actual command line
    var p = initOptParser("--headless --silent --turbo --profile=600 test.gb")
    while true:
        p.next()
        case p.kind
        of cmdEnd: break
        of cmdShortOption, cmdLongOption:
            if p.val == "":
                if p.key == "headless":
                    args.headless = true
                if p.key == "silent":
                    args.silent = true
                if p.key == "turbo":
                    args.turbo = true
                if p.key == "debug_cpu":
                    args.debug_cpu = true
                if p.key == "debug_gpu":
                    args.debug_gpu = true
                if p.key == "debug_apu":
                    args.debug_apu = true
                if p.key == "debug_ram":
                    args.debug_ram = true
            else:
                if p.key == "profile":
                    args.profile = parseInt(p.val)
        of cmdArgument:
            args.rom = p.key

    return args
