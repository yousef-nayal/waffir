#!/bin/sh
set -eu

: "${APP_KEY:?APP_KEY must be set in the Railway environment}"
: "${JWT_SECRET:?JWT_SECRET must be set in the Railway environment}"
: "${DATABASE_URL:?DATABASE_URL must be set in the Railway environment}"

PORT="${PORT:-80}"
find /etc/apache2/mods-enabled -maxdepth 1 -type l -name 'mpm_*' -delete
a2enmod mpm_prefork >/dev/null
sed -ri "s/^Listen 80$/Listen ${PORT}/; s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/" \
	/etc/apache2/ports.conf /etc/apache2/sites-available/000-default.conf

php artisan config:clear
php artisan migrate --force
php artisan config:cache

exec "$@"
