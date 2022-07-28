#!/bin/bash
for run in */run.sh ; do
    n=$(dirname $run)
    out=$(cd $n && ./run.sh --profile 600 --silent --headless --turbo ../test_roms/games/opus5.gb 2>&1 | grep frames)
    printf "%5s %s\n" "$n:" "$out"
done
