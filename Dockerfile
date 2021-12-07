FROM alpine:latest

ENV TIMEZONE            Asia/Shanghai
ENV PHP_MEMORY_LIMIT    512M
ENV MAX_UPLOAD          50M
ENV PHP_MAX_FILE_UPLOAD 200
ENV PHP_MAX_POST        100M

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN apk update \
    && apk upgrade \
    && apk add \
    tzdata \
    nginx \
    php7 \
    php7-dev \
    php7-fpm \
    php7-bcmath \
    php7-xmlwriter \
    php7-ctype \
    php7-curl \
    php7-exif \
    php7-iconv \
    php7-intl \
    php7-json \
    php7-mbstring\
    php7-opcache \
    php7-openssl \
    php7-pdo \
    php7-mysqlnd \
    php7-mysqli \
    php7-pdo_mysql \
    php7-phar \
    php7-posix \
    php7-session \
    php7-xml \
    php7-simplexml \
    php7-mcrypt \
    php7-xsl \
    php7-zip \
    php7-zlib \
    php7-dom \
    php7-tokenizer \
    php7-gd \
    php7-fileinfo \
    php7-xmlreader \
    supervisor \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && apk del tzdata \
    && rm -rf /var/cache/apk/*

RUN sed -i \
        -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/pm.max_children = 5/pm.max_children = 4/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/user = nobody/user = nginx/g" \
        -e "s/group = nobody/group = nginx/g" \
        -e "s/;listen.mode = 0660/listen.mode = 0666/g" \
        -e "s/;listen.owner = nobody/listen.owner = nginx/g" \
        -e "s/;listen.group = nobody/listen.group = nginx/g" \
        -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        /etc/php7/php-fpm.d/www.conf && \
    sed -i \
        -e "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" \
        -e "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" \
        -e "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|i" \
        -e "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" \
        -e "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" \
        -e "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" \
        /etc/php7/php.ini

COPY ./supervisor /etc/supervisor.d
COPY ./conf/php-server.conf /etc/nginx/http.d/default.conf
COPY ./index.php /www/wwwroot/index.php

EXPOSE 8080

ENTRYPOINT ["supervisord", "-n", "-c", "/etc/supervisord.conf"]