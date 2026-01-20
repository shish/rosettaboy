#!/usr/bin/env bash
set -eu

cd $(dirname $0)
if [ ! -d node_modules ] ; then
    npm install
fi
npm run build

cat >rosettaboy-release <<EOD
#!/usr/bin/env bash
set -eu
# gdb -batch -ex "run" -ex "bt" --args
node --enable-source-maps "\$(dirname \$0)/dist/index.js" \$*
EOD
chmod +x rosettaboy-release
