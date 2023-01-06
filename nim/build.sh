#!/usr/bin/env bash
set -eu

cd $(dirname $0)
nimble --accept build -d:release -d:nimDebugDlOpen
mv ./rosettaboy ./rosettaboy-release
