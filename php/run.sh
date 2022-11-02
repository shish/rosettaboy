#!/bin/sh
if [ -f /tmp/php-sdl/modules/sdl.so ] ; then
    FLAGS=-dextension=/tmp/php-sdl/modules/sdl.so
else
    FLAGS=
fi
php $FLAGS -dopcache.enable_cli=1 -dopcache.jit_buffer_size=100M src/main.php $*
