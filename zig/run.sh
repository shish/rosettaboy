#!/usr/bin/env bash
set -eu

cd $(dirname $0)
zig build -Drelease-fast=true
exec ./zig-out/bin/rosettaboy $*
