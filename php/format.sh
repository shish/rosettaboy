#!/usr/bin/env bash
set -eu

cd $(dirname $0)

composer install
PHP_CS_FIXER_IGNORE_ENV=1 ./vendor/bin/php-cs-fixer fix
./vendor/bin/phpstan analyse --error-format raw -c .phpstan.neon
