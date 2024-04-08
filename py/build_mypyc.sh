#!/usr/bin/env bash
set -eu
cd $(dirname $0)

BUILDDIR=${BUILD_ROOT:-$(realpath $(dirname $0))/build}/$(basename $(pwd))-$(echo $(basename $0) | sed 's/build_*\(.*\).sh/\1/')-$(uname)-$(uname -m)-venv
if [ ! -d $BUILDDIR ] ; then
	python3 -m venv $BUILDDIR
	$BUILDDIR/bin/pip install pysdl2 pysdl2-dll 'mypy>=1.0.0'
fi
source $BUILDDIR/bin/activate

rm -rf rbmp
cp -r src rbmp
sed -i.bak 's/from src./from rbmp./' rbmp/*.py
rm -f rbmp/*.bak
mypyc rbmp

cat >rosettaboy-mypyc <<EOD
#!/usr/bin/env bash
set -eu
source $BUILDDIR/bin/activate
PYTHONPATH="\$(dirname \$0)" exec python3 -c "from rbmp.main import main ; import sys ; sys.exit(main(sys.argv))" \$*
EOD
chmod +x rosettaboy-mypyc
