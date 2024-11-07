FROM debian:bookworm-slim

LABEL author="Veslys" maintainer="vesly@vesly.dev"

ARG PHP_VERSION="7.4"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y git apt-transport-https lsb-release ca-certificates wget nginx \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        php${PHP_VERSION} \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-mysqlnd \
        php${PHP_VERSION}-PDO \
        php${PHP_VERSION}-sybase \
        php${PHP_VERSION}-psr \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-calendar \
        php${PHP_VERSION}-ctype \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-dom \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-fileinfo \
        php${PHP_VERSION}-ftp \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-gettext \
        php${PHP_VERSION}-gmp \
        php${PHP_VERSION}-iconv \
        php${PHP_VERSION}-igbinary \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-imap \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-ldap \
        php${PHP_VERSION}-exif \
        php${PHP_VERSION}-memcache \
        php${PHP_VERSION}-mongodb \
        php${PHP_VERSION}-msgpack \
        php${PHP_VERSION}-mysqli \
        php${PHP_VERSION}-odbc \
        php${PHP_VERSION}-pcov \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-Phar \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fSL 'http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz' -o ioncube.tar.gz \
    && mkdir -p ioncube \
    && tar -xf ioncube.tar.gz -C ioncube --strip-components=1 \
    && rm ioncube.tar.gz \
    && mv ioncube/ioncube_loader_lin_7.4.so /var/www/ioncube_loader_lin_7.4.so \
    && rm -r ioncube

# composer
RUN curl -S https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer self-update


RUN useradd -m -d /home/container/ -s /bin/bash container
ENV USER=container HOME=/home/container

WORKDIR /home/container

STOPSIGNAL SIGINT

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD /entrypoint.sh