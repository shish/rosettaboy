#!/usr/bin/env bash
set -eu

cd $(dirname $0)

BUILDDIR=${BUILD_ROOT:-build}/$(basename $(pwd))-$(uname)-$(uname -m)-black
if [ ! -d $BUILDDIR ] ; then
	python3 -m venv $BUILDDIR
	$BUILDDIR/bin/pip install pysdl2 pysdl2-dll 'mypy>=1.0.0' black
fi

$BUILDDIR/bin/black src/*.py
$BUILDDIR/bin/mypy src/*.py
