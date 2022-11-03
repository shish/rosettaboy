#!/bin/bash -eu
cd $(dirname $0)
BUILDDIR=build/$(hostname)
cmake -DCMAKE_BUILD_TYPE=Release -B $BUILDDIR .
cmake --build $BUILDDIR -j
exec $BUILDDIR/rosettaboy-cpp $*
