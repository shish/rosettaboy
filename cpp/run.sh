#!/usr/bin/env bash
set -eu

cd $(dirname $0)
BUILDDIR=build/$(uname)-$(uname -m)
cmake -DCMAKE_BUILD_TYPE=Release -B $BUILDDIR .
cmake --build $BUILDDIR -j
exec $BUILDDIR/rosettaboy-cpp $*
