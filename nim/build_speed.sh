#!/usr/bin/env bash
set -eu

cd $(dirname $0)
nimble --accept build -d:danger --opt:speed -d:lto --mm:arc --panics:on
mv ./rosettaboy ./bin.speed
cat >rosettaboy-speed <<EOD
#!/bin/sh
DYLD_LIBRARY_PATH=\$(dirname \$0) exec \$(dirname \$0)/bin.speed \$*
EOD
chmod +x rosettaboy-speed
