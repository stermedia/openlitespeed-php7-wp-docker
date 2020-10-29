FROM ubuntu:20.04

ARG OLS_VERSION=1.6.16-1+focal
ARG PHP_VERSION=7.4
ARG LSPHP_VERSION=lsphp74
ARG WORDPRESS_VERSION=5.5.1
ARG WORDPRESS_SHA1=d3316a4ffff2a12cf92fde8bfdd1ff8691e41931
ARG LSCACHE_PLUGIN_VERSION=3.5.2

WORKDIR /usr/local/lsws/

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    wget \
    unzip

# Install openlistespeed
RUN wget -O - http://rpms.litespeedtech.com/debian/enable_lst_debian_repo.sh | bash
RUN apt-get update && apt-get install -y openlitespeed=$OLS_VERSION

# Install PHP
RUN apt-get install -y --no-install-recommends \
    $LSPHP_VERSION \
    $LSPHP_VERSION-common \
    $LSPHP_VERSION-mysql \
    $LSPHP_VERSION-json \
    $LSPHP_VERSION-opcache \
    $LSPHP_VERSION-imap \
    $LSPHP_VERSION-dev \
    $LSPHP_VERSION-curl \
    $LSPHP_VERSION-dbg
RUN ln -s /usr/local/lsws/$LSPHP_VERSION/bin/php$PHP_VERSION /usr/bin/php

# Install wordpress
RUN wget --no-check-certificate -O wordpress.tar.gz https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz
RUN echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c -;
RUN tar -xzvf wordpress.tar.gz  >/dev/null 2>&1 && rm wordpress.tar.gz

# Install litespeed cache plugin
RUN wget -O litespeed-cache.zip https://downloads.wordpress.org/plugin/litespeed-cache.${LSCACHE_PLUGIN_VERSION}.zip \
    && unzip litespeed-cache.zip -d ./wordpress/wp-content/plugins/ \
    && rm litespeed-cache.zip
#RUN wget -q -r --level=0 -nH --cut-dirs=2 --no-parent https://plugins.svn.wordpress.org/litespeed-cache/trunk/ --reject html -P ./wordpress/wp-content/plugins/litespeed-cache/
RUN chown -R --reference=./autoupdate ./wordpress

RUN rm -rf \
    /usr/local/lsws/conf/httpd_config.conf \
    /usr/local/lsws/$LSPHP_VERSION/etc/php/$PHP_VERSION/litespeed/php.ini \
    /var/lib/apt/lists/* \
    ./enable_lst_debain_repo.sh \
    /usr/local/lsws/conf/vhosts/Example \
    && apt-get remove --purge -y \
    wget \
    unzip

RUN touch /usr/local/lsws/logs/error.log \
    && touch /usr/local/lsws/logs/access.log \
    # && ln -sf /dev/stdout /usr/local/lsws/logs/access.log \
    # && ln -sf /dev/stderr /usr/local/lsws/logs/error.log \
    && ln -sf /usr/local/lsws/lsphp74/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp \
    && ln -sf /usr/local/lsws/lsphp74/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp7

COPY ./httpd_config.conf /usr/local/lsws/conf/
COPY ./php.ini /usr/local/lsws/$LSPHP_VERSION/etc/php/$PHP_VERSION/litespeed/
COPY ./entrypoint.sh /

RUN chmod +x /entrypoint.sh

VOLUME ["/usr/local/lsws/wordpress"]

EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
EXPOSE 7080
EXPOSE 7080/udp

ENV PATH=/usr/local/lsws/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    DB_NAME='wordpress' \
    DB_USERNAME='root' \
    DB_PASSWORD='' \
    DB_HOST='localhost' \
    SERVER_EMAIL='info@localhost' \
    SERVER_LOGIN='admin' \
    SERVER_PASSWORD='123456' \
    SSL_COUNTRY='US' \
    SSL_STATE='New Jersey' \
    SSL_LOCALITY='Virtual' \
    SSL_ORG='LiteSpeedCommunity' \
    SSL_ORGUNIT='Testing' \
    SSL_HOSTNAME='webadmin' \
    SSL_EMAIL='.' \
    WORDPRESS_TABLE_PREFIX='wp_' \
    WORDPRESS_DEBUG='false' \
    WORDPRESS_CACHE='false' \
    PHP_MEMORY_LIMIT='512M' \
    PHP_MAX_EXECUTION_TIME='1800' \
    PHP_MAX_INPUT_TIME='60' \
    PHP_POST_MAX_SIZE='2048M' \
    PHP_UPLOAD_MAX_FILESIZE='2048M' \
    DOMAIN_URL='*' \
    PROTOCOL='https' \
    WPPORT='80' \
    SSLWPPORT='443' \
    OLS_DEBUG_LEVEL='0' \
    OLS_MAX_REQ_BODY_SIZE='2047M' \
    OLS_MAX_DYN_RESP_SIZE='2047M' \
    OLS_INIT_TIMEOUT='60' \
    OLS_PROC_HARD_LIMIT='500' \
    OLS_PROC_SOFT_LIMIT='500' \
    EXTRA_HEADER='Access-Control-Allow-Origin *' \
    LOG_DEBUG='0'

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail -f /usr/local/lsws/logs/access.log | sed 's/^/[LOG: ]/' & tail -f /usr/local/lsws/logs/error.log | sed 's/^/[ERROR: ]/'"]

# [supervisord]
# nodaemon=true

# [program:startup]
# priority=1
# command=/root/credentialize_and_run.sh
# stdout_logfile=/var/log/supervisor/%(program_name)s.log
# stderr_logfile=/var/log/supervisor/%(program_name)s.log
# autorestart=false
# startsecs=0

# [program:nginx]
# priority=10
# command=nginx -g "daemon off;"
# stdout_logfile=/var/log/supervisor/nginx.log
# stderr_logfile=/var/log/supervisor/nginx.log
# autorestart=true

# CMD ["/usr/bin/supervisord", "-n"]