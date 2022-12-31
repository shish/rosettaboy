#!/usr/bin/env bash
set -eu

cd $(dirname $0)
nimble --accept build -d:debug -d:nimDebugDlOpen
mv ./rosettaboy ./bin.debug
cat >rosettaboy-debug <<EOD
#!/bin/sh
DYLD_LIBRARY_PATH=\$(dirname \$0) exec \$(dirname \$0)/bin.debug \$*
EOD
chmod +x rosettaboy-debug
