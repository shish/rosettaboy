# Instead of being run, this gets `source`d by `build.sh` and `format.sh`.

BUILDDIR=$(dirname $0)/venv/$(uname)-$(uname -m)

# Use existing libraries (E.G. from system, or from Nix) if found.
if python3 -c 'import sdl2, black, mypy' 2>/dev/null ; then
	echo "Python packages found:"
	python3 -c 'import sdl2, black, mypy; [print(module.__file__) for module in [sdl2, black, mypy]]'
else
	if [ ! -d $BUILDDIR ] ; then
		echo "Installing PySDL2, MyPy, and Black in $BUILDDIR"
		python3 -m venv $BUILDDIR
		$BUILDDIR/bin/pip install pysdl2 pysdl2-dll 'mypy>=1.0.0' black
	fi
	# echo "Using Python3 in $BUILDDIR"
	PATH="$BUILDDIR/bin:$PATH"
fi
