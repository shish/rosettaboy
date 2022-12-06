#!/usr/bin/env bash
set -eu

cd $(dirname $0)

PATH="$(realpath -m './vendor/bin'):$PATH"

php-cs-fixer fix
