#!/bin/sh
nimble --accept build -d:release && ./rosettaboy $*
