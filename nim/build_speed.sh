#!/usr/bin/env bash
set -eu

# I don't know how to add lld to the path in a generic way,
# so I'm hardcoding something that works for me, pull requests
# accepted :)
export PATH="/Users/shish2k/homebrew/opt/llvm/bin:$PATH"

cd $(dirname $0)
nimble --accept build -d:danger --opt:speed -d:lto --mm:arc --panics:on
cp ./rosettaboy ./rosettaboy-speed
