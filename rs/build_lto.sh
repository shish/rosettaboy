#!/usr/bin/env bash
set -eu

cd $(dirname $0)
cargo build --profile release-lto
cp ./target/release-lto/rosettaboy-rs ./rosettaboy-lto