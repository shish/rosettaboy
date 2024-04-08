#!/usr/bin/env bash
set -eu

cd $(dirname $0)

VENVDIR=${BUILD_ROOT:-$(realpath $(dirname $0))/build}/$(basename $(pwd))-$(uname)-$(uname -m)-black
if [ ! -d $VENVDIR ]; then
	python3 -m venv $VENVDIR
	$VENVDIR/bin/pip install pysdl2 pysdl2-dll mypy black Cython==3.0.0a11
fi

$VENVDIR/bin/black src/*.py
