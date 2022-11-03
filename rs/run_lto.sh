#!/bin/bash
cd $(dirname $0)
cargo +nightly -Z unstable-options run --profile release-lto -- $*
