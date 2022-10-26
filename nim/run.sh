#!/bin/bash
nimble build -d:release --opt:speed
./rosettaboy $*
