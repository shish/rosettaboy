#!/usr/bin/env bash
set -eu

cd $(dirname $0)
cd ..

if command -v nix-shell; then
    if [ -n "$*" ]; then
        nix-shell --run "$*"
    else
        nix-shell
    fi
else
    ./utils/shell-docker "$@"
fi
