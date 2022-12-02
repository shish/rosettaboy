#!/bin/bash -eu
cd $(dirname $0)
BUILDDIR=venv/$(hostname)
if [ ! -d $BUILDDIR ] ; then
	python3.11 -m venv $BUILDDIR
	$BUILDDIR/bin/pip install pysdl2 pysdl2-dll mypy black
fi
exec $BUILDDIR/bin/python3 -m src.main $*
