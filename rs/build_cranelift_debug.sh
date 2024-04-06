#!/usr/bin/env bash
set -eu

cd $(dirname $0)
BUILDDIR=${BUILD_ROOT:-target/cranelift}/$(basename $(pwd))-$(echo $(basename $0) | sed 's/build_*\(.*\).sh/\1/')-$(uname)-$(uname -m)
export CARGO_PROFILE_DEV_CODEGEN_BACKEND=cranelift
export CARGO_TARGET_DIR=$BUILDDIR
cargo +nightly build -Zcodegen-backend --release
cp $BUILDDIR/debug/rosettaboy-rs ./rosettaboy-debug