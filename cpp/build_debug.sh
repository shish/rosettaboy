#!/usr/bin/env bash
set -eu

cd $(dirname $0)
BUILDDIR=build/debug/$(uname)-$(uname -m)
cmake -DCMAKE_BUILD_TYPE=Debug -B $BUILDDIR .
cmake --build $BUILDDIR -j
cp $BUILDDIR/rosettaboy-cpp ./rosettaboy-debug
