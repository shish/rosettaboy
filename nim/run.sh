#!/bin/bash -eu
cd $(dirname $0)
nimble --accept build -d:release
exec ./rosettaboy $*
