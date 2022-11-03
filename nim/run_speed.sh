#!/bin/bash
cd $(dirname $0)
nimble --accept build -d:release --opt:speed && ./rosettaboy $*
