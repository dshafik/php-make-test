FROM debian:jessie
RUN apt-get update --fix-missing
RUN echo "mysql-server mysql-server/root_password password \"''\"" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password \"''\"" | debconf-set-selections
RUN apt-get install --yes build-essential mysql-server postgresql libgd-dev libxml2 libxslt1-dev libtidy-dev libreadline6 gettext libfreetype6 git autoconf bison re2c openssl pkg-config libssl-dev libbz2-dev  libcurl4-openssl-dev libenchant-dev libgmp-dev libicu-dev libmcrypt-dev postgresql-server-dev-all libpspell-dev libreadline-dev

ENV MYSQL_TEST_HOST="127.0.0.1" MYSQL_TEST_USER="root" PDO_MYSQL_TEST_DSN="mysql:host=127.0.0.1;dbname=test" PDO_MYSQL_TEST_USER="root" PDO_MYSQL_TEST_HOST="127.0.0.1"

RUN git clone https://github.com/php/php-src.git
WORKDIR php-src

RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h

RUN service mysql start && sleep 10 && ./travis/ext/mysql/setup.sh
RUN service mysql start && sleep 10 && ./travis/ext/mysqli/setup.sh
RUN service mysql start && sleep 10 && ./travis/ext/pdo_mysql/setup.sh
RUN service postgresql start && sleep 10 && echo '\
<?php $conn_str .= " user=postgres"; ?>' >> "./ext/pgsql/tests/config.inc" && su postgres -c "psql -c 'create database test;' -U postgres"

ENV PDO_PGSQL_TEST_DSN="pgsql:host=localhost port=5432 dbname=test user=postgres password="

#ENV ENABLE_MAINTAINER_ZTS=0 ENABLE_DEBUG=0
ARG BUILD_NAME
ENV BUILD_NAME $BUILD_NAME
ENV HOME /$BUILD_NAME
RUN mkdir $HOME

CMD git fetch --all; git checkout $PHP_TEST_BRANCH; git pull; ./travis/compile.sh; service mysql start; service postgresql start; sleep 10 && ./sapi/cli/php run-tests.php -p `pwd`/sapi/cli/php -g "FAIL" --offline --show-diff --set-timeout 120
