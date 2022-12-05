#!/usr/bin/env bash
set -eu

cd $(dirname $0)

source py_env.sh

exec black src/*.py
