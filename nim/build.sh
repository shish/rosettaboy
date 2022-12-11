#!/usr/bin/env bash
set -eu

cd $(dirname $0)
nimble --accept build -d:release
mv ./rosettaboy ./bin.release
cat >rosettaboy-release <<EOD
#!/bin/sh
DYLD_LIBRARY_PATH=\$(dirname \$0) exec \$(dirname \$0)/bin.release \$*
EOD
chmod +x rosettaboy-release
