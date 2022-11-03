#!/bin/bash
cd $(dirname $0)
if [ ! -d ../venv ] ; then
	python3.11 -m venv ../venv
	../venv/bin/pip install pysdl2 pysdl2-dll
fi
../venv/bin/python3 -m src.main $*
