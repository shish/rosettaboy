#!/bin/sh -eu
TARGET=$(rustc -vV | grep host: | sed 's/host: //')

# STEP 0: Make sure there is no left-over profiling data from previous runs
rm -rf /tmp/pgo-data

# STEP 1: Build the instrumented binaries
RUSTFLAGS="-Cprofile-generate=/tmp/pgo-data" \
    cargo build --release --target=$TARGET

# STEP 2: Run the instrumented binaries with some typical data
./target/$TARGET/release/rosettaboy-rs --profile 600 --silent --headless --turbo ../test_roms/games/opus5.gb >/dev/null
./target/$TARGET/release/rosettaboy-rs --profile 600 --silent --headless --turbo ../test_roms/games/opus5.gb >/dev/null
./target/$TARGET/release/rosettaboy-rs --profile 600 --silent --headless --turbo ../test_roms/games/opus5.gb >/dev/null

# STEP 3: Merge the `.profraw` files into a `.profdata` file
xcrun llvm-profdata merge -o /tmp/pgo-data/merged.profdata /tmp/pgo-data

# STEP 4: Use the `.profdata` file for guiding optimizations
RUSTFLAGS="-Cprofile-use=/tmp/pgo-data/merged.profdata" \
    cargo build --release --target=$TARGET

exec ./target/$TARGET/release/rosettaboy-rs $*
