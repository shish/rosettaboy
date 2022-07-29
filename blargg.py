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
from glob import glob
from multiprocessing.pool import ThreadPool


RED = "\033[0;31m"
GREEN = "\033[0;32m"
END = "\033[0m"
TEST_DIR = "gb-autotest-roms"

if not os.path.exists(TEST_DIR):
    subprocess.run(
        ["git", "clone", "https://github.com/shish/gb-autotest-roms", TEST_DIR]
    )


def test(cwd, rom):
    cmd = [
        "./run.sh",
        "--turbo",
        "--silent",
        "--headless",
        f"../{rom}",
    ]
    p = subprocess.run(
        cmd,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    ok = p.returncode == 0
    # ok = b"Passed" in p.stdout or b"Unit test" in p.stdout
    rom_name = rom.replace(f"{TEST_DIR}/", "")
    print(f"{cwd} {rom_name} = {GREEN if ok else RED}{ok}{END}")
    return ok


dirs = sys.argv[1:] or [n.replace("/run.sh", "") for n in glob("*/run.sh")]
roms = glob("gb-autotest-roms/*/*.gb")
tests_to_run = itertools.product(dirs, roms)

p = ThreadPool(8)
results = p.starmap(test, tests_to_run)
if all(results):
    sys.exit(0)
else:
    sys.exit(1)
