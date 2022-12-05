#!/usr/bin/env bash
set -eu

TARGET=$(rustc -vV | grep host: | sed 's/host: //')
PGO_DATA=/tmp/pgo-rs-data

# STEP 0: Make sure there is no left-over profiling data from previous runs
rm -rf $PGO_DATA

# STEP 1: Build the instrumented binaries
RUSTFLAGS="-Cprofile-generate=$PGO_DATA" \
    cargo build --release --target=$TARGET

# STEP 2: Run the instrumented binaries with some typical data
./target/$TARGET/release/rosettaboy-rs --frames 10 -SHt ../test_roms/games/opus5.gb >/dev/null

# STEP 3: Merge the `.profraw` files into a `.profdata` file
llvm-profdata merge -o $PGO_DATA/merged.profdata $PGO_DATA

# STEP 4: Use the `.profdata` file for guiding optimizations
RUSTFLAGS="-Cprofile-use=$PGO_DATA/merged.profdata" \
    cargo build --release --target=$TARGET

exec ./target/$TARGET/release/rosettaboy-rs $*
