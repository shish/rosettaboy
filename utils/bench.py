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

for lang_runner in glob("*/run*.sh"):
    lang = os.path.dirname(lang_runner)
    runner = os.path.basename(lang_runner)

    if sys.argv[1:] and lang not in sys.argv[1:]:
        continue

    sub = "release"
    if match := re.match("run_(.*).sh", runner):
        sub = match.group(1)
    proc = subprocess.run(
        [
            f"./{runner}",
            "--profile",
            "600",
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
