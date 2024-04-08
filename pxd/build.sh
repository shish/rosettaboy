#!/usr/bin/env bash
set -eu

cd $(dirname $0)

BUILDDIR=${BUILD_ROOT:-build}/$(basename $(pwd))-$(echo $(basename $0) | sed 's/build_*\(.*\).sh/\1/')-$(uname)-$(uname -m)-build
VENVDIR=${BUILD_ROOT:-build}/$(basename $(pwd))-$(echo $(basename $0) | sed 's/build_*\(.*\).sh/\1/')-$(uname)-$(uname -m)-venv

if [ ! -d $VENVDIR ]; then
	python3 -m venv $VENVDIR
	$VENVDIR/bin/pip install pysdl2 pysdl2-dll mypy black Cython==3.0.0a11
fi
source $VENVDIR/bin/activate

python3 setup.py build "$@" \
	--build-base "$BUILDDIR/base" \
	--build-purelib "$BUILDDIR/purelib" \
	--build-lib "$BUILDDIR/lib" \
	--build-scripts "$BUILDDIR/scripts" \
	--build-temp "$BUILDDIR/temp" \
	--parallel 4

cat >rosettaboy-release <<EOD
#!/usr/bin/env bash
set -eu
source $VENVDIR/bin/activate
PYTHONPATH="$BUILDDIR/lib/" exec python3 "$BUILDDIR/scripts/main.py" \$*
EOD
chmod +x rosettaboy-release
