#!/bin/bash -eu
cd $(dirname $0)
nimpretty --indent:4 --maxLineLen:120 src/*.nim
