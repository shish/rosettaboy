#!/usr/bin/env bash
set -eu
cd $(dirname $0)
source py_env.sh

cat >rosettaboy-release <<EOD
#!/usr/bin/env bash
set -eu
source "\$(dirname \$0)/py_env.sh"
PYTHONPATH="\$(dirname \$0)" exec python3 -c "from src.main import main ; import sys ; sys.exit(main(sys.argv))" \$*
EOD
chmod +x rosettaboy-release
