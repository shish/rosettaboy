#!/bin/bash
cd $(dirname $0)
docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) -t rosettaboy . && \
docker run --rm --privileged -ti -v $(pwd)/..:/home/dev rosettaboy
