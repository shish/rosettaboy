#!/usr/bin/env bash
set -eu

cd $(dirname $0)

source py_env.sh

black src/*.py
mypy src/*.py
