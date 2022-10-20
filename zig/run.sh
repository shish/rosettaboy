#!/bin/sh
zig build -fstage1 -Drelease-fast=true && exec ./zig-out/bin/rosettaboy $*
