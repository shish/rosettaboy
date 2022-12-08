#!/bin/bash
cd $(dirname $0)

# If we are running in a terminal, then run docker in terminal mode
if [ -t 1 ] ; then
    FLAGS=-ti
else
    FLAGS=
fi

docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) -t rosettaboy . && \
docker run --rm --privileged $FLAGS -v $(pwd)/..:/home/dev/rosettaboy rosettaboy $*