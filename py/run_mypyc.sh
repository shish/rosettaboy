#!/bin/bash -eu
cd $(dirname $0)
BUILDDIR=venv/$(hostname)
if [ ! -d $BUILDDIR ] ; then
	python3.11 -m venv $BUILDDIR
	$BUILDDIR/bin/pip install pysdl2 pysdl2-dll mypy
fi
$BUILDDIR/bin/mypyc main.py
exec $BUILDDIR/bin/python3 -c 'import main' $*
