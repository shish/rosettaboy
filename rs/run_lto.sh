#!/bin/sh
cargo +nightly -Z unstable-options run --profile release-lto -- $*
