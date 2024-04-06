#!/usr/bin/env bash
set -eu

cd $(dirname $0)
BUILDDIR=${BUILD_ROOT:-target}/$(basename $(pwd))-$(echo $(basename $0) | sed 's/build_*\(.*\).sh/\1/')-$(uname)-$(uname -m)
export CARGO_TARGET_DIR=$BUILDDIR
cargo build --release
cp $BUILDDIR/release/rosettaboy-rs ./rosettaboy-release