Utils
=====

shell.sh + Docker
-----------------
An attempt to build a dockerfile with all of the necessary
dependencies to run any implementation (headless and silent)

Run `./utils/shell.sh` to get a shell where you can then
`cd` to language and `./run.sh` to run it.


blargg.py
---------
Run a slightly-hacked version of Blargg's test suite. Specifically
it is hacked to run a specific invalid opcode for "test passed" and
a different one for "test failed".


bench.sh
--------
Find all of the `run*.sh` launchers and run them with a standard set
of command line options


cpudiff.py
----------
Spot the different between two `--debug-cpu` log files