#!/bin/bash -eu
cd $(dirname $0)
exec go run src/*.go $*
