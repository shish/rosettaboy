#!/usr/bin/env bash
set -eu

cd $(dirname $0)
zig fmt src/*.zig