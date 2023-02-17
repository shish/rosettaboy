#!/usr/bin/env bash
set -eu

cd $(dirname $0)
nimble --accept build -d:release --opt:speed -d:lto -d:nimDebugDlOpen
mv ./rosettaboy ./rosettaboy-lto
