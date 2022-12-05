#!/usr/bin/env bash
set -eu

cd $(dirname $0)

source py_env.sh

mypyc main.py
exec python3 -c 'import main' $*
