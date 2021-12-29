#!/usr/bin/env sh

cp .env.example .env
chown -R $USER:www-data storage
chown -R $USER:www-data bootstrap/cache
chmod -R 775 storage
chmod -R 775 bootstrap/cache
php /app/artisan key:generate
php /app/artisan config:cache
php /app/artisan route:cache
php /app/artisan view:cache
/usr/local/sbin/php-fpm
rm -rf .env

exec "$@"
