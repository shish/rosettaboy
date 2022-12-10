#!/usr/bin/env bash
set -eu
cd $(dirname $0)

cat >rosettaboy-opcache <<EOD
#!/usr/bin/env bash
set -eu

cd \$(dirname \$0)
if [ -f \${HOME}/php-sdl/modules/sdl.so ] ; then
    FLAGS=-dextension=\${HOME}/php-sdl/modules/sdl.so
else
    FLAGS=
fi
exec php \$FLAGS -dopcache.enable_cli=1 -dopcache.jit_buffer_size=100M src/main.php \$*
EOD
chmod +x rosettaboy-opcache
