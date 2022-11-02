#!/bin/sh
zig build -Drelease-safe=true && exec ./zig-out/bin/rosettaboy $*
