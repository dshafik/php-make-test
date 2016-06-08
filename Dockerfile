FROM debian:jessie
RUN apt-get update --fix-missing
RUN echo "mysql-server mysql-server/root_password password \"''\"" | debconf-set-selections 
RUN echo "mysql-server mysql-server/root_password_again password \"''\"" | debconf-set-selections 
RUN apt-get install --yes build-essential
RUN apt-get install --yes mysql-server postgresql
RUN apt-get install --yes libgd-dev libxml2 libxslt1-dev libtidy-dev libreadline6 gettext libfreetype6 
RUN apt-get install --yes git
RUN apt-get install --yes autoconf
RUN apt-get install --yes bison re2c
RUN apt-get install --yes openssl pkg-config libssl-dev
RUN apt-get install --yes libbz2-dev  libcurl4-openssl-dev libenchant-dev libgmp-dev libicu-dev libmcrypt-dev postgresql-server-dev-all libpspell-dev libreadline-dev

ENV MYSQL_TEST_HOST="127.0.0.1" MYSQL_TEST_USER="root" PDO_MYSQL_TEST_DSN="mysql:host=127.0.0.1;dbname=test" PDO_MYSQL_TEST_USER="root" PDO_MYSQL_TEST_HOST="127.0.0.1"

RUN git clone --depth 1  https://github.com/php/php-src.git
WORKDIR php-src

RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h

RUN service mysql start && sleep 10 && ./travis/ext/mysql/setup.sh
RUN service mysql start && sleep 10 && ./travis/ext/mysqli/setup.sh
RUN service mysql start && sleep 10 && ./travis/ext/pdo_mysql/setup.sh
RUN service postgresql start && sleep 10 && echo '\ 
<?php $conn_str .= " user=postgres"; ?>' >> "./ext/pgsql/tests/config.inc" && su postgres -c "psql -c 'create database test;' -U postgres"

ENV PDO_PGSQL_TEST_DSN="pgsql:host=localhost port=5432 dbname=test user=postgres password="

ENV ENABLE_MAINTAINER_ZTS=0 ENABLE_DEBUG=0
ENV HOME=/no-zts-no-debug
RUN mkdir $HOME
RUN ./travis/compile.sh
RUN service mysql start; service postgresql start; sleep 10 && ./sapi/cli/php run-tests.php -p `pwd`/sapi/cli/php -g "FAIL,XFAIL,BORK,WARN,LEAK,SKIP" --offline --show-diff --set-timeout 120

ENV ENABLE_MAINTAINER_ZTS=1 ENABLE_DEBUG=0
ENV HOME=/zts-no-debug
RUN make clean
RUN mkdir $HOME
RUN ./travis/compile.sh
RUN service mysql start; service postgresql start; sleep 10 && ./sapi/cli/php run-tests.php -p `pwd`/sapi/cli/php -g "FAIL,XFAIL,BORK,WARN,LEAK,SKIP" --offline --show-diff --set-timeout 120

ENV ENABLE_MAINTAINER_ZTS=0 ENABLE_DEBUG=1
ENV HOME=/no-zts-debug
RUN make clean
RUN mkdir $HOME
RUN ./travis/compile.sh
RUN service mysql start; service postgresql start; sleep 10 && ./sapi/cli/php run-tests.php -p `pwd`/sapi/cli/php -d opcache.enable_cli=1 -d zend_extension=`pwd`/modules/opcache.so -g "FAIL,XFAIL,BORK,WARN,LEAK,SKIP" --offline --show-diff --set-timeout 120

ENV ENABLE_MAINTAINER_ZTS=1 ENABLE_DEBUG=1
ENV HOME=/zts-debug
RUN make clean
RUN mkdir $HOME
RUN ./travis/compile.sh
RUN service mysql start; service postgresql start; sleep 10 && ./sapi/cli/php run-tests.php -p `pwd`/sapi/cli/php -d opcache.enable_cli=1 -d zend_extension=`pwd`/modules/opcache.so -g "FAIL,XFAIL,BORK,WARN,LEAK,SKIP" --offline --show-diff --set-timeout 120
