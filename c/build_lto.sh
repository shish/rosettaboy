#!/usr/bin/env bash
set -eu

cd $(dirname $0)
BUILDDIR=build/lto/$(uname)-$(uname -m)
cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_LTO=On -B $BUILDDIR .
cmake --build $BUILDDIR -j
cp $BUILDDIR/rosettaboy-c ./rosettaboy-lto
