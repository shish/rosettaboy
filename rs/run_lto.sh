#!/bin/sh
cargo -Z unstable-options run --profile release-lto -- $*
