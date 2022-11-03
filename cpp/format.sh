#!/bin/sh
if command -v clang-format-14 &> /dev/null ; then
    CMD=clang-format-14
else
    CMD=clang-format
fi
$CMD -i $(find src -type f | grep -v _args.h) --ferror-limit 10 -Werror