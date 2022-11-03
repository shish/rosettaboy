#!/usr/bin/env python3
"""
a script to compare CPU traces - when one implementation is failing
tests, it can be useful to compare results against a known-good one

Usage:
  cd cpp && ./run.sh -SHtp30 ../test_roms/games/opus5.gb --debug-cpu > ../cpp-linux.cpu
  cd rs && ./run.sh -SHtp30 ../test_roms/games/opus5.gb --debug-cpu > ../rs-linux.cpu
  ./utils/cpudiff.py *.cpu
"""

import typing as t
import sys
import re

pattern = re.compile("([0-9A-F]{4} ){4}")


def find_valid_lines(fn: str) -> t.Iterable[str]:
    for line in open(fn):
        if pattern.match(line):
            yield line.strip()


last = []
skipped = 0

for lines in zip(*[find_valid_lines(fn) for fn in sys.argv[1:]]):
    if len(set(lines)) == 1:
        last.append(lines[0])
        if len(last) > 5:
            skipped += 1
            last.pop(0)
    else:
        print(f"Skipped {skipped} common lines")
        for l in last:
            print(l)
        for n, l in enumerate(lines):
            print(f"{l}   # {sys.argv[n+1]}")
        break
