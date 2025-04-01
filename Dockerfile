#
# Dockerfile to run php 5.3 as fpm
#
# https://github.com/heisenbergdo/docker-php5.3-apple-silicon
#
# The last version of php 5.3 is from August 14, 2014.
# Do not use it unless you know what you are doing#
#
# This release works with Docker on Apple-Silicon and
# and perhaps only on this platform
#

FROM arm64v8/debian:jessie-slim

# minimal sources
COPY ./apt/sources.list /etc/apt/sources.list
# allow unauthenticated packages because gpg-key is expired
COPY ./apt/allowUnauthenticated.conf /etc/apt/apt.conf.d/allowUnauthenticated

# some required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/*

# compile openssl 1.0.2u
RUN apt-get update && apt-get install -y --no-install-recommends \
      autoconf \
      g++ \
      gcc \
      make \
 && cd /tmp \
 && mkdir openssl \
 && curl -SL "https://www.php.net/distributions/php-5.4.33.tar.gz" -o php.tar.gz \
 && echo "74e542dd2f15ebbc123738a71e867d57d2996a6edb40e6ac62fcf5ab85763d19 php.tar.gz" | sha256sum --check \
 && echo "$(cat openssl.tar.gz.sha256) openssl.tar.gz" | sha256sum --check \
 && tar -xzf openssl.tar.gz -C openssl --strip-components=1 \
 && /bin/rm openssl.tar.gz \
 && cd /tmp/openssl \
 && ./config -fPIC \
 && make -j $(nproc) && make install \
 && ln -s /usr/lib/aarch64-linux-gnu /usr/local/ssl/lib/ \
 && /bin/rm -r /tmp/openssl \
 && apt-get clean \
 && apt-get autoremove --purge -y \
      autoconf \
      g++ \
      gcc \
      make

# compile php 5.3.29
ENV PHP_INI_DIR /etc/php5/php-fpm
RUN mkdir -p $PHP_INI_DIR/conf.d
COPY ./php/php-fpm.conf $PHP_INI_DIR/php-fpm.conf

RUN apt-get update && apt-get install -y --no-install-recommends \
      libjpeg62-turbo \
      libmcrypt4 \
      libmysqlclient18 \
      librecode0 \
      libxml2 \
      autoconf \
      g++ \
      gcc \
      make \
      libcurl4-openssl-dev \
      libjpeg-dev \
      libmcrypt-dev \
      libmysqlclient-dev \
      libpng-dev \
      libreadline6-dev \
      librecode-dev \
      libssl-dev \
      libxml2-dev \
      libzip-dev \
  && cd /tmp \
  && mkdir -p /tmp/php \
  && curl -SL "https://www.php.net/distributions/php-5.3.29.tar.gz" -o php.tar.gz \
  && echo "57cf097de3d6c3152dda342f62b1b2e9c988f4cfe300ccfe3c11f3c207a0e317 php.tar.gz" | sha256sum --check \
  && tar -xzf php.tar.gz -C /tmp/php --strip-components=1 \
  && rm php.tar.gz* \
  && cd /tmp/php \
  && curl -o config.guess -L 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' \
  && curl -o config.sub -L 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD' \
  && ./configure --disable-cgi \
         --enable-fpm \
         --with-config-file-path="$PHP_INI_DIR" \
         --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
         --enable-ftp \
         --enable-mbstring \
         --enable-mysqlnd \
         --with-mysql \
         --with-mysqli \
         --with-pdo-mysql \
         --with-curl \
         --with-openssl-dir=/usr/local/ssl \
         --enable-soap \
         --with-png-dir \
         --with-jpeg-dir \
         --with-gd \
         --with-readline \
         --with-recode \
         --with-zlib-dir \
         --with-libxml-dir \
         --with-mcrypt \
         --enable-zip \
         --without-pear \
         --host $(uname -m) \
         --with-libdir=/lib/aarch64-linux-gnu/ | tee -a /tmp/php.log \
 && make -j "$(nproc)" \
 && make install \
 && /bin/rm -r /tmp/php \
 && apt-get clean \
 && apt-get autoremove --purge -y \
      autoconf \
      g++ \
      gcc \
      make \
      libcurl4-openssl-dev \
      libjpeg-dev \
      libmcrypt-dev \
      libmysqlclient-dev \
      libpng-dev \
      libreadline6-dev \
      librecode-dev \
      libssl-dev \
      libxml2-dev \
      libzip-dev

EXPOSE 9000
CMD ["php-fpm", "--pid", "/run/php-fpm.pid", "--fpm-config", "/etc/php5/php-fpm/php-fpm.conf"]
