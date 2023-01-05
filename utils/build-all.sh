#!/usr/bin/env bash
set -eu

cd $(dirname $0)/..
for n in $(ls */build*.sh | grep -v utils); do
    echo ==========================
    echo $n
    $n || echo "($n failed)"
done
