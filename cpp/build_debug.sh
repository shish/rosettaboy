#!/usr/bin/env bash
set -eu

cd $(dirname $0)
BUILDDIR=${BUILD_ROOT:-build}/$(basename $(pwd))-$(echo $(basename $0) | sed 's/build_*\(.*\).sh/\1/')-$(uname)-$(uname -m)
cmake -DCMAKE_BUILD_TYPE=Debug -B $BUILDDIR .
cmake --build $BUILDDIR -j
cp $BUILDDIR/rosettaboy-cpp ./rosettaboy-debug
