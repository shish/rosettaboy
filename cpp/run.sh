#!/bin/bash
cd $(dirname $0)
cmake -DCMAKE_BUILD_TYPE=Release . && make -j && ./rosettaboy-cpp $*
