#!/usr/bin/env bash
set -eu

cd $(dirname $0)
zig build -Doptimize=ReleaseFast
mv ./zig-out/bin/rosettaboy ./rosettaboy-release
