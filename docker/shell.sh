#!/bin/bash
docker build -t rosettaboy .
docker run --privileged -ti -v $(pwd)/..:/home/dev rosettaboy
