#!/bin/bash -eu
cd $(dirname $0)
./vendor/bin/php-cs-fixer fix
