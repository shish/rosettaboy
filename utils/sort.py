#!/usr/bin/env python3

import sys
import re

def getkey(line):
    matches = re.search("([0-9]+)fps", line)
    if matches:
        return int(matches.group(1))
    return 0

lines = sys.stdin.read().split("\n")
lines = sorted(lines, key=getkey, reverse=True)
print("\n".join(lines))
