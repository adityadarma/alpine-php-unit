ARG ALPINE_VERSION

FROM adityadarma/alpine-php-unit:core-${ALPINE_VERSION}

USER root

ARG PHP_VERSION
ARG PHP_NUMBER
ARG VARIANT=full

ENV VALIDATE_TIMESTAMPS=1
ENV REVALIDATE_FREQ=2
ENV WITH_QUEUE=false
ENV WITH_SCHEDULE=false
ENV PHP_NUMBER=${PHP_NUMBER}
ENV PHP_WORKER_MEMORY=32
ENV UNIT_MAX_PROCESSES=
ENV UNIT_SPARE_PROCESSES=

# Set label information
LABEL org.opencontainers.image.php="${PHP_VERSION}"

# Install package
RUN echo "VARIANT=${VARIANT}" && apk add --update --no-cache \
    unit-php${PHP_NUMBER} \
    php${PHP_NUMBER} \
    php${PHP_NUMBER}-curl \
    php${PHP_NUMBER}-ctype \
    php${PHP_NUMBER}-dom \
    php${PHP_NUMBER}-fileinfo \
    php${PHP_NUMBER}-json \
    php${PHP_NUMBER}-mbstring \
    php${PHP_NUMBER}-opcache \
    php${PHP_NUMBER}-openssl \
    php${PHP_NUMBER}-tokenizer \
    && case "$VARIANT" in \
    mini) apk add --no-cache \
    php${PHP_NUMBER}-bcmath \
    php${PHP_NUMBER}-iconv \
    php${PHP_NUMBER}-pdo_mysql \
    php${PHP_NUMBER}-pdo_sqlite \
    php${PHP_NUMBER}-phar \
    php${PHP_NUMBER}-session ;; \
    full|node) apk add --no-cache \
    mysql-client \
    php${PHP_NUMBER}-bcmath \
    php${PHP_NUMBER}-exif \
    php${PHP_NUMBER}-gd \
    php${PHP_NUMBER}-iconv \
    php${PHP_NUMBER}-mysqli \
    php${PHP_NUMBER}-pdo_mysql \
    php${PHP_NUMBER}-pdo_pgsql \
    php${PHP_NUMBER}-pdo_sqlite \
    php${PHP_NUMBER}-pecl-imagick \
    php${PHP_NUMBER}-phar \
    php${PHP_NUMBER}-session \
    php${PHP_NUMBER}-simplexml \
    php${PHP_NUMBER}-xml \
    php${PHP_NUMBER}-xmlreader \
    php${PHP_NUMBER}-xmlwriter \
    php${PHP_NUMBER}-zip \
    php${PHP_NUMBER}-zlib ;; \
    esac \
    && if [ "$VARIANT" = "node" ]; then apk add --no-cache nodejs npm; fi \
    && rm -rf /var/cache/apk/*

# Symlink if not found
RUN if [ ! -e /usr/bin/php ]; then ln -s /usr/bin/php${PHP_NUMBER} /usr/bin/php; fi

# Install composer from the official image
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Copy file configurator
COPY custom/php.ini /etc/php${PHP_NUMBER}/conf.d/custom.ini
COPY custom/unit.config.json /var/lib/unit/conf.json

# Setup document root
WORKDIR /app

# Pre-load Unit configuration into statedir at build time
RUN /usr/sbin/unitd --no-daemon --log /dev/null & \
    until [ -S /run/control.unit.sock ]; do sleep 0.1; done && \
    curl -sf -X PUT --unix-socket /run/control.unit.sock \
    --data-binary @/var/lib/unit/conf.json http://localhost/config && \
    kill $(cat /run/unit.pid) 2>/dev/null; \
    rm -f /run/control.unit.sock /run/unit.pid

# Make sure files/folders needed by the processes are accessible
RUN chown -R unit:unit /app /run /var/lib/unit /var/log /etc/supervisord.conf

# Switch to non-root user for security
USER unit