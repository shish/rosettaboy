#!/usr/bin/env bash
set -eu

cd $(dirname $0)
cargo build --release
cp target/release/rosettaboy-rs ./rosettaboy-release