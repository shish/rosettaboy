#!/usr/bin/env python3
"""
a script to compare CPU traces - when one implementation is failing
tests, it can be useful to compare results against a known-good one

Usage:
  cd nim && ./run.sh -HSt --debug-cpu ../gb-autotest-roms/blargg-cpu-instructions/02-interrupts.gb > ../nim.cpu && cd ..
  cd rs && ./run.sh -HSt --debug-cpu ../gb-autotest-roms/blargg-cpu-instructions/02-interrupts.gb > ../rs.cpu && cd ..
  python3 cpudiff.py nim.cpu rs.cpu
"""

import sys

last = []

f1 = open(sys.argv[1])
f2 = open(sys.argv[2])

for l1, l2 in zip(f1, f2):
    if l1 == l2:
        last.append(l1)
        if len(last) > 5:
            last.pop(0)
    else:
        for l in last:
            print("R:", l.strip())
        print("X:", l1.strip())
        print("Y:", l2.strip())
        break
