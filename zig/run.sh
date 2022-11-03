#!/bin/bash -eu
cd $(dirname $0)
zig build -Drelease-fast=true
exec ./zig-out/bin/rosettaboy $*
