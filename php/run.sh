#!/bin/sh
# opcache in 8.1 gives a nice speedup (25s to 10s)
if [ -f /usr/local/Cellar/php/8.1.0/bin/php ] ; then
    /usr/local/Cellar/php/8.1.0/bin/php \
        -dopcache.enable_cli=1 -dopcache.jit_buffer_size=100M \
        src/main.php $*
else
    php src/main.php $*
fi