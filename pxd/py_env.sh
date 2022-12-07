# Instead of being run, this gets `source`d by `run.sh` and `format.sh`.

BUILDDIR=venv/$(hostname)
PYIMPORT_EXIT=$(python3 -c 'import sdl2, black, mypy, cython' 1>&2; echo $?) # Use existing libraries (E.G. from system, or from Nix) if found.
if [ $PYIMPORT_EXIT -eq 0 ] ; then
	echo "Python packages found:"
	python3 -c 'import sdl2, black, mypy, cython; [print(module.__file__) for module in [sdl2, black, mypy, cython]]'
else
	if [ ! -d $BUILDDIR ] ; then
		echo "Installing PySDL2, MyPy, Black, and Cython in $BUILDDIR"
		python3 -m venv $BUILDDIR
		$BUILDDIR/bin/pip install pysdl2 pysdl2-dll mypy black Cython==3.0.0a11
	fi
	echo "Using Python3 in $BUILDDIR"
	PATH="$BUILDDIR/bin:$PATH"
fi