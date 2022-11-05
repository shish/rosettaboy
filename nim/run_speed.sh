#!/bin/bash -eu
cd $(dirname $0)
nimble --accept build -d:danger --opt:speed -d:lto --mm:arc --panics:on
exec ./rosettaboy $*
