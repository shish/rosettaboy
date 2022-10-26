#!/bin/sh
php -dopcache.enable_cli=1 -dopcache.jit_buffer_size=100M src/main.php $*
