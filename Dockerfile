FROM php:8.0.1-fpm

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    curl -s http://nginx.org/keys/nginx_signing.key | apt-key add - && \
    codename=$(cat /etc/os-release | grep VERSION= | awk -F "(" '{ print $2 }' | awk -F ")" '{ print $1 }') && \
    echo "deb http://nginx.org/packages/mainline/debian/ ${codename} nginx \ndeb-src http://nginx.org/packages/mainline/debian/ ${codename} nginx" > /etc/apt/sources.list.d/nginx.list && \
    apt-get update && \
    apt-get install -y \
      autoconf \
      build-essential \
      nodejs && \
    pecl install \
      mongodb \
      redis && \
    mv $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini && \
    echo "extension=mongodb.so" >> /usr/local/etc/php/conf.d/mongodb.ini && \
    echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini && \
    apt-get install -y \
      cron \
      git \
      zip \
      curl \
      sudo \
      unzip \
      libpq-dev \
      libonig-dev \
      libicu-dev \
      libfcgi-bin \
      libbz2-dev \
      libpng-dev \
      libjpeg-dev \
      libmcrypt-dev \
      libreadline-dev \
      libfreetype6-dev \
      nginx \
      g++ && \
    docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
    docker-php-ext-install \
      bz2 \
      pdo \
      intl \
      pgsql \
      iconv \
      bcmath \
      opcache \
      calendar \
      mbstring \
      pdo_pgsql \
      gd && \
    curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php --version=2.0.8 --install-dir=/usr/local/bin --filename=composer && \
    chmod +x /usr/local/bin/composer && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    apt-get clean


ENV BASE_PATH=/var/www/html/laravelapp
WORKDIR ${BASE_PATH}

# COPY package* ./
# RUN npm install

# COPY composer* ./
# RUN composer install --optimize-autoloader

# COPY ./ ./
# RUN rm -rf docker-entrypoint.sh && \
#     npm run production && \
#     chmod 777 /var/www/html/laravelapp/bootstrap

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Information about commit, that was used for building the docker image
ARG BACKEND_VERSION=unknown
ENV BACKEND_VERSION=${BACKEND_VERSION}

RUN cat /etc/os-release

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["backend"]

