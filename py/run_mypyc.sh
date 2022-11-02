#!/bin/sh
if [ ! -d ../venv ] ; then
	python3.11 -m venv ../venv
	../venv/bin/pip install pysdl2 pysdl2-dll mypy
fi
../venv/bin/mypyc main.py
../venv/bin/python3 -c 'import main' $*
