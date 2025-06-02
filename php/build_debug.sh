#!/usr/bin/env bash
set -eu
cd $(dirname $0)

cat >rosettaboy-debug <<EOD
#!/usr/bin/env bash
set -eu

if [ -f \${HOME}/php-sdl/modules/sdl.so ] ; then
    FLAGS=-dextension=\${HOME}/php-sdl/modules/sdl.so
else
    FLAGS=
fi
export XDEBUG_MODE=debug
exec php \$FLAGS "\$(dirname \$0)/src/main.php" \$*
EOD
chmod +x rosettaboy-debug
