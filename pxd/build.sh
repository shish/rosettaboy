#!/usr/bin/env bash
set -eu

cd $(dirname $0)

BUILDDIR=${BUILD_ROOT:-$(realpath $(dirname $0))/build}/$(basename $(pwd))-$(echo $(basename $0) | sed 's/build_*\(.*\).sh/\1/')-$(uname)-$(uname -m)-build
VENVDIR=${BUILD_ROOT:-$(realpath $(dirname $0))/build}/$(basename $(pwd))-$(echo $(basename $0) | sed 's/build_*\(.*\).sh/\1/')-$(uname)-$(uname -m)-venv

if [ ! -d $VENVDIR ]; then
	python3 -m venv $VENVDIR
fi
source $VENVDIR/bin/activate

pip install -e .

cat >rosettaboy-release <<EOD
#!/usr/bin/env bash
set -eu
source $VENVDIR/bin/activate
PYTHONPATH="$BUILDDIR/lib/" exec python3 "$BUILDDIR/scripts/main.py" \$*
EOD
chmod +x rosettaboy-release
