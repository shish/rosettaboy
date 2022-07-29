#!/bin/sh
cmake -DCMAKE_BUILD_TYPE=Release .  # or Debug
make -j
./rosettaboy-cpp $*
