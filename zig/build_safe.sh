#!/usr/bin/env bash
set -eu

cd $(dirname $0)
zig build -Doptimize=ReleaseSafe
mv ./zig-out/bin/rosettaboy ./rosettaboy-safe
