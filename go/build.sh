#!/usr/bin/env bash
set -eu

cd $(dirname $0)
go build -o rosettaboy-release src/*.go
