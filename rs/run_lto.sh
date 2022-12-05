#!/usr/bin/env bash
set -eu

cd $(dirname $0)
exec cargo run --profile release-lto -- $*
