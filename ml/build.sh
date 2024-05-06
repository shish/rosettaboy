#!/bin/sh
opam exec -- dune build
mv ./_build/default/bin/main.exe ./rosettaboy-release