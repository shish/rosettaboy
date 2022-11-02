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
from multiprocessing.pool import ThreadPool

TEST_ROM_URL = "https://github.com/sjl/cl-gameboy/blob/master/roms/opus5.gb?raw=true"
TEST_ROM = "opus5.gb"
if not os.path.exists(TEST_ROM):
    subprocess.run(
        ["wget", TEST_ROM_URL, "-O", TEST_ROM],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=True,
    )


def test(lang: str, runner: str, sub: str, frames: int, profile: int) -> bool:
    # Some languages have orders-of-magnitudes of differences in speed
    proc = subprocess.run(
        [
            f"./{runner}",
            "--frames",
            str(frames),
            "--profile",
            str(profile),
            "--silent",
            "--headless",
            "--turbo",
            f"../{TEST_ROM}",
        ],
        cwd=lang,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if proc.returncode != 0:
        print(f"{lang:>5s} / {sub:7s}: Failed\n{proc.stdout}")
        return False
    else:
        frames = ""
        for line in proc.stdout.split("\n"):
            if "frames" in line:
                frames = line
        print(f"{lang:>5s} / {sub:7s}: {frames}")
        return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--default",
        default=False,
        action="store_true",
        help="Only run the default run.sh, not variants",
    )
    parser.add_argument(
        "--threads",
        type=int,
        default=1,
        help="How many tests to run in parallel",
    )
    parser.add_argument(
        "--frames", type=int, default=0, help="Run for this many frames"
    )
    parser.add_argument(
        "--profile", type=int, default=0, help="Run for this many seconds"
    )
    parser.add_argument("langs", default=[], nargs="*", help="Which languages to test")
    args = parser.parse_args()
    if args.frames == 0 and args.profile == 0:
        args.profile = 10

    tests_to_run = []
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
        tests_to_run.append((lang, runner, sub, args.frames, args.profile))

    p = ThreadPool(args.threads)
    results = p.starmap(test, tests_to_run)
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
