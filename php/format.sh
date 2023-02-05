#!/usr/bin/env bash
set -eu

cd $(dirname $0)

composer install
./vendor/bin/php-cs-fixer fix
./vendor/bin/phpstan analyse --error-format raw -c .phpstan.neon
