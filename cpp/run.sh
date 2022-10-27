#!/bin/sh
# Build types: Release, Debug
cmake -DCMAKE_BUILD_TYPE=Release . && make -j && ./rosettaboy-cpp $*
