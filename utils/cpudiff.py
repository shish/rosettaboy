#!/usr/bin/env python3
"""
a script to compare CPU traces - when one implementation is failing
tests, it can be useful to compare results against a known-good one

For example, nim has some GPU weirdness, let's see if there're any
differences happening at the CPU level:

$ ./cpp/rosettaboy-release -SHtf5 ../test_roms/games/opus5.gb --debug-cpu > cpp.cpu
$ ./zig/rosettaboy-release -SHtf5 ../test_roms/games/opus5.gb --debug-cpu > zig.cpu
$ ./nim/rosettaboy-release -SHtf5 ../test_roms/games/opus5.gb --debug-cpu > nim.cpu
$ ./utils/cpudiff.py *.cpu
Skipped 37 common lines
00C0 4000 00D8 014D : FFF4 = 0000 : ZNhc : v____ : 017E = CD : CALL $01E4
00C0 4000 00D8 014D : FFF2 = 0181 : ZNhc : v____ : 01E4 = 21 : LD HL,$8000
00C0 4000 00D8 8000 : FFF2 = 0181 : ZNhc : v____ : 01E7 = 16 : LD D,$10
00C0 4000 10D8 8000 : FFF2 = 0181 : ZNhc : v____ : 01E9 = 1E : LD E,$40
00C0 4000 1040 8000 : FFF2 = 0181 : ZNhc : v____ : 01EB = F0 : LDH A,[$41]
04C0 4000 1040 8000 : FFF2 = 0181 : ZNhc : v____ : 01ED = E6 : AND $02   # cpp.log
00C0 4000 1040 8000 : FFF2 = 0181 : ZNhc : v____ : 01ED = E6 : AND $02   # nim.log
04C0 4000 1040 8000 : FFF2 = 0181 : ZNhc : v____ : 01ED = E6 : AND $02   # zig.log

Looks like after loading the value of address 0xFF41 (the GPU's STAT
register) into the CPU A register, C++ and Zig both think A should be 0x04,
but Nim thinks that A should be 0x00. This suggests that Nim isn't updating
the STAT register properly.
"""

import typing as t
import sys
import re
import argparse

pattern = re.compile("(([0-9A-F]{4} ){4}|ram)")


def find_valid_lines(fn: str) -> t.Iterable[str]:
    log_started = False
    for line in open(fn):
        if log_started or pattern.match(line):
            log_started = True
            yield line.strip()


def run(files: t.List[str], before: int) -> None:
    last = []
    skipped = 0

    for lines in zip(*[find_valid_lines(fn) for fn in files]):
        if len(set(lines)) == 1:
            last.append(lines[0])
            if len(last) > before:
                skipped += 1
                last.pop(0)
        else:
            print(f"Skipped {skipped} common lines")
            for l in last:
                print(l)
            for n, l in enumerate(lines):
                print(f"{l}   # {files[n]}")
            break

def main(argv) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("-B", "--before", default=5, type=int, help="Common lines to show before diff")
    parser.add_argument("files", nargs="+", help="CPU log files to compare")
    args = parser.parse_args()

    run(args.files, args.before)

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
