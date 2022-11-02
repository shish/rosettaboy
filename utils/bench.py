#!/usr/bin/env python3

"""
Usage: ./utils/bench.py zig rs cpp

Will find any run*.sh scripts in the named directories
(eg run.sh, run_pgo.sh, run_pypy.sh) and run them with
a standard set of args.
"""
from glob import glob
import subprocess
import os
import re
import sys
import argparse

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--default", default=False, action="store_true", help="Only run the default run.sh, not variants")
    parser.add_argument("--frames", type=int, default=600, help="Run for this many frames")
    parser.add_argument("langs", default=[], nargs="*")
    args = parser.parse_args()

    all_ok = True

    for lang_runner in glob("*/run*.sh"):
        lang = os.path.dirname(lang_runner)
        runner = os.path.basename(lang_runner)
        sub = "release"
        if match := re.match("run_(.*).sh", runner):
            sub = match.group(1)

        if args.langs and lang not in args.langs:
            continue
        if args.default and sub != "release":
            continue

        proc = subprocess.run(
            [
                f"./{runner}",
                "--profile",
                str(args.frames),
                "--silent",
                "--headless",
                "--turbo",
                "../test_roms/games/opus5.gb",
            ],
            cwd=lang,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        frames = ""
        for line in proc.stdout.split("\n"):
            if "frames" in line:
                frames = line
        print(f"{lang:>5s} / {sub:7s}: {frames}")
        if proc.returncode != 0:
            all_ok = False

    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())