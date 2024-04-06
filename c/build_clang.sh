#!/usr/bin/env bash
set -eu

export CC=clang CXX=clang++
cd $(dirname $0)
BUILDDIR=${BUILD_ROOT:-build}/$(basename $(pwd))-$(echo $(basename $0) | sed 's/build_*\(.*\).sh/\1/')-$(uname)-$(uname -m)
cmake -DCMAKE_BUILD_TYPE=Release -B $BUILDDIR .
cmake --build $BUILDDIR -j
cp $BUILDDIR/rosettaboy-c ./rosettaboy-clang
