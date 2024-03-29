#!/usr/bin/env bash
set -eu

cd $(dirname $0)

source py_env.sh

BUILD_DIR=build
CORES=$(python3 -c 'import os; print(os.cpu_count() or 0)')

if [ -t "$CORES" ]; then
	echo "Failed to find core count." 1>&2
	CORES=1
else
	echo "Found $CORES cores." 1>&2
fi

python3 setup.py build "$@" --build-base "$BUILD_DIR" --build-purelib "$BUILD_DIR" --build-lib "$BUILD_DIR" --build-scripts "$BUILD_DIR" --build-temp build_temp --parallel $CORES

cat >rosettaboy-release <<EOD
#!/usr/bin/env bash
set -eu
source "\$(dirname \$0)/py_env.sh"
PYTHONPATH="\$(dirname \$0)/build/" exec python3 "\$(dirname \$0)/build/main.py" \$*
EOD
chmod +x rosettaboy-release