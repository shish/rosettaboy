#!/bin/sh
zig build -Drelease-fast=false && exec ./zig-out/bin/rosettaboy $*