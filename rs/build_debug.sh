#!/usr/bin/env bash
set -eu

cd $(dirname $0)
cargo build
cp target/debug/rosettaboy-rs ./rosettaboy-debug