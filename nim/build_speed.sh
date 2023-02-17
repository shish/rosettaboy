set -eu

cd $(dirname $0)
nimble --accept build -d:danger --opt:speed -d:lto
mv ./rosettaboy ./rosettaboy-speed
