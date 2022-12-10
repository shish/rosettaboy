#!/usr/bin/env python3

import sdl2
import sys
from typing import List

from src.args import parse_args
from src.gameboy import GameBoy
from src.errors import GameException, UserException, ControlledExit, EmuError


def main(argv: List[str]) -> int:
    args = parse_args(argv[1:])

    try:
        gameboy = GameBoy(args)
        gameboy.run()
    except EmuError as e:
        print(e)
        return e.exit_code
    except (KeyboardInterrupt, BrokenPipeError):
        pass
    finally:
        sdl2.SDL_Quit()

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
