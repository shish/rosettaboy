#!/bin/sh
if [ ! -d ../venv ] ; then
	python3 -m venv ../venv
	../venv/bin/pip install pysdl2 pysdl2-dll
fi
../venv/bin/python3 -m src.main $*
