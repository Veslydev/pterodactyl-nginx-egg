FROM debian:bookworm-slim

LABEL author="YmoT" maintainer="YmoT@tuta.com"

ARG PHP_VERSION

ENV DEBIAN_FRONTEND=noninteractive

# Install basic packages
RUN apt-get update && apt-get install -y \
        git \
        apt-transport-https \
        lsb-release \
        ca-certificates \
        wget \
        nginx \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Cloudflared
RUN ARCH=$(uname -m) \
    && if [ "$ARCH" = "x86_64" ]; then \
        wget -O /tmp/cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb; \
    elif [ "$ARCH" = "aarch64" ]; then \
        wget -O /tmp/cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi \
    && dpkg -i /tmp/cloudflared.deb \
    && rm /tmp/cloudflared.deb

# Add PHP repository
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list \
    && apt-get update

# Install PHP core packages
RUN apt-get install -y --no-install-recommends \
        php${PHP_VERSION} \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
    && rm -rf /var/lib/apt/lists/*

# Install PHP database extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
        php${PHP_VERSION}-pdo \
        php${PHP_VERSION}-pdo-mysql \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-mysqli \
    && rm -rf /var/lib/apt/lists/*

# Install PHP essential extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mcrypt \
        php${PHP_VERSION}-fileinfo \
        php${PHP_VERSION}-hash \
        php${PHP_VERSION}-json \
    && rm -rf /var/lib/apt/lists/*

# Install PHP XML extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-dom \
        php${PHP_VERSION}-simplexml \
        php${PHP_VERSION}-xmlreader \
        php${PHP_VERSION}-xmlwriter \
    && rm -rf /var/lib/apt/lists/*

# Install PHP additional extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-openssl \
        php${PHP_VERSION}-session \
        php${PHP_VERSION}-tokenizer \
        php${PHP_VERSION}-ctype \
        php${PHP_VERSION}-filter \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN wget -q -O /tmp/composer.phar https://getcomposer.org/download/latest-stable/composer.phar \
    && SHA256=$(wget -q -O - https://getcomposer.org/download/latest-stable/composer.phar.sha256) \
    && echo "$SHA256 /tmp/composer.phar" | sha256sum -c - \
    && mv /tmp/composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer

RUN set -eux; \
    ARCH=$(uname -m); \
    PHP_EXT_DIR=$(php -r "echo ini_get('extension_dir');"); \
    PHP_MAJOR_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;"); \
    if [ "$ARCH" = "x86_64" ]; then \
        IONCUBE_ARCH="x86-64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        IONCUBE_ARCH="aarch64"; \
    else \
        echo "Unsupported architecture: $ARCH" >&2; exit 1; \
    fi; \
    cd /tmp; \
    wget -O ioncube.tar.gz "https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_${IONCUBE_ARCH}.tar.gz"; \
    tar xzf ioncube.tar.gz; \
    cp ioncube/ioncube_loader_lin_${PHP_MAJOR_VERSION}.so "$PHP_EXT_DIR"; \
    echo "zend_extension=${PHP_EXT_DIR}/ioncube_loader_lin_${PHP_MAJOR_VERSION}.so" > /etc/php/${PHP_VERSION}/cli/conf.d/00-ioncube.ini; \
    echo "zend_extension=${PHP_EXT_DIR}/ioncube_loader_lin_${PHP_MAJOR_VERSION}.so" > /etc/php/${PHP_VERSION}/fpm/conf.d/00-ioncube.ini; \
    rm -rf /tmp/ioncube*

# Create user and set environment variables
RUN useradd -m -d /home/container/ -s /bin/bash container \
    && echo "USER=container" >> /etc/environment \
    && echo "HOME=/home/container" >> /etc/environment

WORKDIR /home/container

STOPSIGNAL SIGINT

# Copy entrypoint script
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
