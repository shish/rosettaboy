#!/usr/bin/env bash
set -eu

cd $(dirname $0)
zig build -Drelease-fast=true
cp ./zig-out/bin/rosettaboy ./rosettaboy-release
