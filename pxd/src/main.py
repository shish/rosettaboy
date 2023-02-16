#!/usr/bin/env python3

import cython

if not cython.compiled:
    import sdl2

import sys
from typing import List
from traceback import print_exception

from .args import parse_args
from .gameboy import GameBoy
from .errors import GameException, UserException, ControlledExit, EmuError


def main(argv: List[str]) -> int:
    args = parse_args(argv[1:])

    try:
        gameboy = GameBoy(args)
        gameboy.run()
    except EmuError as e:
        if isinstance(e, ControlledExit):
            print(e)
        else:
            print_exception(e)
        return e.exit_code
    except (KeyboardInterrupt, BrokenPipeError):
        pass
    finally:
        sdl2.SDL_Quit()

    return 0


def cli_main():
    sys.exit(main(sys.argv))


if __name__ == "__main__":
    cli_main()
