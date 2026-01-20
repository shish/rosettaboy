#!/usr/bin/env bash
set -eu

if [ ! -d node_modules ] ; then
    npm install
fi
npm run format
