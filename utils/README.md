Utils
=====

shell.sh + Nix / Docker
-----------------------
Convenience script to get a shell with all tools and dependencies needed to run any implementation.

Run `./utils/shell.sh` to get a shell where you can then `cd` to language and `./build.sh` to build it.

If Nix is available, it will use that. Otherwise, it will fallback to `shell-docker.sh`.


shell-docker.sh + Docker
------------------------
An attempt to build a dockerfile with all of the necessary
dependencies to run any implementation (headless and silent)


blargg.py
---------
Run a slightly-hacked version of Blargg's test suite. Specifically
it is hacked to run a specific invalid opcode for "test passed" and
a different one for "test failed".


bench.sh
--------
Find all of the `rosettaboy-*` variants and run them with a standard set
of command line options


cpudiff.py
----------
Spot the difference between two `--debug-cpu` log files