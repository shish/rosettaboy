#!/usr/bin/env bash
set -eu

cd $(dirname $0)

source py_env.sh

BUILDDIR=${BUILD_ROOT:-build}/$(basename $(pwd))-$(echo $(basename $0) | sed 's/build_*\(.*\).sh/\1/')-$(uname)-$(uname -m)-build
CORES=$(python3 -c 'import os; print(os.cpu_count() or 0)')

if [ -t "$CORES" ]; then
	echo "Failed to find core count." 1>&2
	CORES=1
else
	echo "Found $CORES cores." 1>&2
fi

python3 setup.py build "$@" \
	--build-base "$BUILDDIR/base" \
	--build-purelib "$BUILDDIR/purelib" \
	--build-lib "$BUILDDIR/lib" \
	--build-scripts "$BUILDDIR/scripts" \
	--build-temp "$BUILDDIR/temp" \
	--parallel $CORES

cat >rosettaboy-release <<EOD
#!/usr/bin/env bash
set -eu
source "\$(dirname \$0)/py_env.sh"
PYTHONPATH="$BUILDDIR/lib/" exec python3 "$BUILDDIR/scripts/main.py" \$*
EOD
chmod +x rosettaboy-release
