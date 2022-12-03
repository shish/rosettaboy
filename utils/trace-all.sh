#!/bin/bash
cd $(dirname $0)/..
for runner in */run.sh ; do
    $runner --frames 100 --silent --headless --turbo --debug-cpu --debug-ram "$1" \
        | head -n 10000 > "$(basename $(dirname $runner)).cpu"
done
