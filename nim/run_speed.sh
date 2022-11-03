#!/bin/bash -eu
cd $(dirname $0)
nimble --accept build -d:release --opt:speed
exec ./rosettaboy $*
