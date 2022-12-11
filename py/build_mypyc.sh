#!/usr/bin/env bash
set -eu
cd $(dirname $0)
source py_env.sh
rm -rf rbmp
cp -r src rbmp
gsed -i 's/from src./from rbmp./' rbmp/*.py
mypyc rbmp

cat >rosettaboy-mypyc <<EOD
#!/usr/bin/env bash
set -eu
source "\$(dirname \$0)/py_env.sh"
PYTHONPATH="\$(dirname \$0)" exec python3 -c "from rbmp.main import main ; import sys ; sys.exit(main(sys.argv))" \$*
EOD
chmod +x rosettaboy-mypyc
