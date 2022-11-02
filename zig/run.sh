#!/bin/sh
zig build -Drelease-fast=true && exec ./zig-out/bin/rosettaboy $*
