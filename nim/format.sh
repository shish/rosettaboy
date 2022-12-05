#!/usr/bin/env bash
set -eu

cd $(dirname $0)
nimpretty --indent:4 --maxLineLen:120 src/*.nim
