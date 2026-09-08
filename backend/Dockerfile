FROM php:8.2-apache

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public \
    COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip libpq-dev libzip-dev libonig-dev \
    && docker-php-ext-install -j"$(nproc)" bcmath mbstring opcache pdo_pgsql zip \
    && a2dismod --force mpm_event mpm_worker mpm_prefork || true \
    && find /etc/apache2/mods-enabled -maxdepth 1 -type l -name 'mpm_*' -delete \
    && a2enmod mpm_prefork \
    && a2enmod rewrite headers \
    && sed -ri "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf \
    && sed -ri "s!/var/www/!${APACHE_DOCUMENT_ROOT}/!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && apache2ctl -M 2>&1 | grep -q 'mpm_prefork_module' \
    && ! apache2ctl -M 2>&1 | grep -Eq 'mpm_(event|worker)_module' \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --optimize-autoloader --no-scripts

COPY . .

RUN composer run-script post-autoload-dump --no-interaction

RUN mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R ug+rwx storage bootstrap/cache

COPY docker/entrypoint.sh /usr/local/bin/waffir-entrypoint
RUN chmod +x /usr/local/bin/waffir-entrypoint

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/waffir-entrypoint"]
CMD ["apache2-foreground"]