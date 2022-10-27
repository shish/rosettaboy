#!/bin/sh
nimble build -d:release --opt:speed && ./rosettaboy $*
