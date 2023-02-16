#!/usr/bin/env python3

"""
Usage:
  ./blargg.py <list of directories to test>
Eg:
  ./blargg.py py cpp rs
"""

import os
import subprocess
import sys
import itertools
from multiprocessing.pool import ThreadPool
import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument(
    "--threads",
    type=int,
    default=8,
    help="How many tests to run in parallel",
)
parser.add_argument(
    "--test_rom_dir",
    type=Path,
    default=os.environ.get("GB_DEFAULT_AUTOTEST_ROM_DIR", "gb-autotest-roms"),
    help="The directory with the test ROMS",
    metavar="DIR"
)
parser.add_argument("langs", default=[], nargs="*", help="Which languages to test")
args = parser.parse_args()


RED = "\033[0;31m"
GREEN = "\033[0;32m"
END = "\033[0m"
TEST_DIR = Path(args.test_rom_dir)

if not os.path.exists(TEST_DIR):
    subprocess.run(
        ["git", "clone", "https://github.com/shish/gb-autotest-roms", TEST_DIR]
    )


def build(cwd):
    p = subprocess.run(
        ["./build.sh"],
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        errors="replace",
    )
    if p.returncode == 0:
        print(f"{cwd} = {GREEN}Built{END}")
    else:
        print(f"{cwd} = {RED}Failed{END}\n{p.stdout}")
    return p.returncode == 0

def test(cwd, rom):
    rom_name = rom.relative_to(TEST_DIR)

    if not rom.is_absolute():
        rom = f"../{rom}"

    p = subprocess.run(
        [
            "./rosettaboy-release",
            "--turbo",
            "--silent",
            "--headless",
            "--frames",
            "2000",
            f"{rom}",
        ],
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        errors="replace",
    )
    
    if p.returncode == 0 and "Unit test passed" in p.stdout:
        print(f"{cwd} {rom_name} = {GREEN}Passed{END}")
    elif p.returncode == 2:
        print(f"{cwd} {rom_name} = {RED}Failed{END}")
    else:
        print(f"{cwd} {rom_name} = {RED}Crashed{END}\n{p.stdout}")
    return p.returncode == 0 and "Unit test passed" in p.stdout


dirs = args.langs or [f"{n}".replace("/build.sh", "") for n in Path('.').glob("*/build.sh")]
roms = Path(TEST_DIR).glob(f"*/*.gb")
tests_to_run = itertools.product(dirs, roms)

p = ThreadPool(args.threads)
results = p.starmap(build, [(d, ) for d in dirs])
if all(results):
    results = p.starmap(test, tests_to_run)
    if all(results):
        sys.exit(0)
    else:
        sys.exit(1)
else:
    sys.exit(2)