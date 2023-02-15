#!/usr/bin/env bash
set -eu

cd $(dirname $0)
cd ..

if nix develop --help 2>/dev/null 1>/dev/null; then
    if [ -n "$*" ]; then
        nix develop . --command bash -c "$*"
    else
        nix develop .
    fi
elif command -v nix-shell; then
    if [ -n "$*" ]; then
        nix-shell --run "$*"
    else
        nix-shell
    fi
else
    ./utils/shell-docker "$@"
fi
