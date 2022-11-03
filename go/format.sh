#!/bin/bash -eu
cd $(dirname $0)
go fmt src/*.go
