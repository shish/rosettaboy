#!/bin/bash -eu
cd $(dirname $0)
exec cargo run --profile release-lto -- $*
