#!/usr/bin/env bash
set -eu

cd $(dirname $0)
cargo build --profile release-lto
rm -f ./rosettaboy-lto
mv ./target/release-lto/rosettaboy-rs ./rosettaboy-lto