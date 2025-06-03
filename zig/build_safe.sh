#!/usr/bin/env bash
set -eu

cd $(dirname $0)
zig build --release=safe
mv ./zig-out/bin/rosettaboy ./rosettaboy-safe
