#!/usr/bin/env bash
set -eu

cd $(dirname $0)
zig build #-Drelease-safe=true
exec ./zig-out/bin/rosettaboy $*
