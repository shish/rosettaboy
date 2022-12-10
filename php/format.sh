#!/usr/bin/env bash
set -eu

cd $(dirname $0)

if [ ! -f vendor/bin/php-cs-fixer ] ; then
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    ./composer.phar require friendsofphp/php-cs-fixer
fi

./vendor/bin/php-cs-fixer fix
