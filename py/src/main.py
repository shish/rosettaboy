#!/usr/bin/env python3

from sdl2 import SDL_Quit
import sys
from typing import List

from .args import parse_args
from .gameboy import GameBoy
from .errors import GameException, UserException, ControlledExit, EmuError, 
                    InvalidOpcode, InvalidRamRead, InvalidRamWrite, Quit, Timeout,
                    UnitTestFailed, UnitTestPassed, RomMissing, LogoChecksumFailed,
                    HeaderChecksumFailed


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
    except Exception as e:
        print(str(e))
    finally:
        SDL_Quit()

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
