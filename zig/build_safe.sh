#!/usr/bin/env bash
set -eu

cd $(dirname $0)
zig build -Drelease-safe=true
cp ./zig-out/bin/rosettaboy ./rosettaboy-safe
