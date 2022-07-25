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
from multiprocessing.pool import ThreadPool


if not os.path.exists("gb-test-roms"):
    subprocess.run(["git", "clone", "https://github.com/retrio/gb-test-roms"])


def test(cwd, n, frames):
    cmd = [
        "./run.sh",
        "--turbo",
        "--silent",
        "--headless",
        "--profile",
        str(frames),
        f"../gb-test-roms/cpu_instrs/individual/{n}*.gb",
    ]
    p = subprocess.run(
        cmd,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    ok = b"Passed" in p.stdout or b"passed" in p.stdout
    print(f"{cwd} {n} = {ok}")
    return ok


tests = [
    ("01", 140),
    ("02", 30),
    ("03", 140),
    ("04", 160),
    ("05", 220),
    ("06", 30),
    ("07", 40),
    ("08", 30),
    ("09", 550),
    ("10", 850),
    ("11", 1050),
]

tests_to_run = []
for d in sys.argv[1:]:
    for n, frames in tests:
        tests_to_run.append((d, n, frames))

p = ThreadPool(4)
results = p.starmap(test, tests_to_run)
if all(results):
    sys.exit(0)
else:
    sys.exit(1)
