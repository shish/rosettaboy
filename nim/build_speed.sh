#!/usr/bin/env bash
set -eu

cd $(dirname $0)
nimble --accept build -d:danger --opt:speed -d:lto --mm:refc --panics:on
mv ./rosettaboy ./rosettaboy-speed
