#!/usr/bin/env bash
set -eu

cd $(dirname $0)
zig build --release=fast
mv ./zig-out/bin/rosettaboy ./rosettaboy-release
