#!/bin/sh
clang-format-14 -i $(find src -type f | grep -v _args.h) --ferror-limit 10 -Werror