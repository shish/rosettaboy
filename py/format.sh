#!/bin/bash -eu
cd $(dirname $0)

source py_env.sh

exec black src/*.py
