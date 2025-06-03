#!/usr/bin/env bash
set -eu
cd $(dirname $0)

BUILDDIR=${BUILD_ROOT:-$(realpath $(dirname $0))/build}/$(basename $(pwd))-$(echo $(basename $0) | sed 's/build_*\(.*\).sh/\1/')-$(uname)-$(uname -m)-venv
if [ ! -d $BUILDDIR ] ; then
	pypy3 -m venv $BUILDDIR
	$BUILDDIR/bin/pip install pysdl2 pysdl2-dll
fi
source $BUILDDIR/bin/activate

cat >rosettaboy-pypy <<EOD
#!/usr/bin/env bash
set -eu
source $BUILDDIR/bin/activate
exec python3 -c "from src.main import main ; import sys ; sys.exit(main(sys.argv))" \$*
EOD
chmod +x rosettaboy-pypy
