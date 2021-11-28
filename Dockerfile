#===================================================
# Composer
#===================================================
FROM composer:2.1.3 AS vendor

WORKDIR /app

COPY database/ database/

COPY composer.json composer.json

COPY composer.lock composer.lock

RUN composer install \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --no-dev \
    --prefer-dist

COPY . .

RUN composer dump-autoload
#===================================================
# Nodejs
#===================================================
FROM node:14.16-alpine AS frontend

WORKDIR /app

COPY artisan package.json webpack.mix.js  ./

RUN npm install

COPY resources/js ./resources/js

COPY resources/css ./resources/css

RUN npm run dev

FROM php:8.0-fpm-alpine

LABEL maintainer="Abiyoga Bayu Primadi"

#--------------------------------------------------
# Timezone
#--------------------------------------------------
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#--------------------------------------------------
# APP_ROOT, APP_USER
#--------------------------------------------------
ENV APP_ROOT=/var/www/html \
    APP_USER=www-data

RUN sed -ri 's/^www-data:x:82:82:/www-data:x:1000:50:/' /etc/passwd

RUN set -ex \
    && mkdir -p "${APP_ROOT}" \
    && chown -R "${APP_USER}:${APP_USER}" "${APP_ROOT}"

#--------------------------------------------------
# Copy frontend build
#--------------------------------------------------
COPY --from=frontend /app/node_modules ./var/www/html/node_modules

COPY --from=frontend /app/public/js/ ./var/www/html/public/js/

COPY --from=frontend /app/public/css/ ./var/www/html/public/css/

COPY --from=frontend /app/public/mix-manifest.json ./var/www/html/public/mix-manifest.json

#--------------------------------------------------
# Copy vendor build
#--------------------------------------------------
COPY --from=vendor /app/vendor ./var/www/html/vendor/

COPY . .

#--------------------------------------------------
# PHP
#--------------------------------------------------
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS=1 \
    PHP_OPCACHE_SAVE_COMMENTS=1

RUN set -ex \
    && apk add --no-cache --virtual .php-deps \
        libzip-dev \
        icu-dev \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libxml2-dev \
        git \
        supervisor \
    && git clone https://github.com/phpredis/phpredis.git /usr/src/php/ext/redis \
    && docker-php-ext-configure gd \
        --with-freetype=/usr/include/ \
        --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) \
        intl \
        opcache \
        pdo_mysql \
        gd \
        zip \
        xml \
        redis \
        pcntl

ENV XDEBUG_VERSION=3.0.4 \
    XDEBUG_REMOTE_ENABLE=0 \
    XDEBUG_REMOTE_HOST=docker.for.mac.localhost \
    XDEBUG_REMOTE_PORT=9003

RUN set -ex \
    && apk add --no-cache --virtual .php-xdebug-build-deps \
        autoconf \
        g++ \
        make \
    && pecl install xdebug-${XDEBUG_VERSION} \
    && docker-php-ext-enable xdebug \
    && apk del .php-xdebug-build-deps

COPY ./docker/php/conf.d/*.ini /usr/local/etc/php/conf.d/

EXPOSE 9003
