#!/bin/sh
nimble --accept build -d:release --opt:speed && ./rosettaboy $*
