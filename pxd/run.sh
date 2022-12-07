#!/usr/bin/env bash
set -eu

cd $(dirname $0)

source py_env.sh

./build.sh

exec python3 build/main.py $*
