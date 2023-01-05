#!/usr/bin/env bash
set -eu

cd $(dirname $0)
nimble --accept build -d:danger --opt:speed -d:lto --mm:arc --panics:on
mv ./rosettaboy ./rosettaboy-speed
