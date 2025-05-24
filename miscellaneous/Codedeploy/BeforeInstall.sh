#!/bin/bash

<<<<<<< HEAD

currentDir="$(dirname "$0")"
COMPOSER_CMD=$(command -v composer)
=======
currentDir="$(dirname "$0")"
COMPOSER_CMD=$(which composer)
>>>>>>> bcddde5 (1)
CONF_DIR="$currentDir/conf"
HTTPD_DIR="/etc/httpd"
DEPLOYMENT_GROUP_NAME_ENV=$(echo "$DEPLOYMENT_GROUP_NAME" | cut -d- -f1)

<<<<<<< HEAD
# Detect package manager
if command -v yum &> /dev/null; then
    PM="yum"
elif command -v apt-get &> /dev/null; then
    PM="apt-get"
else
    echo "Unsupported package manager. Exiting."
    exit 1
fi

echo "Using package manager: $PM"

#############################
# Install Apache
#############################
if [[ "$PM" == "yum" ]]; then
    yum install -y httpd24 mod24_ssl
elif [[ "$PM" == "apt-get" ]]; then
    apt-get update
    apt-get install -y apache2
fi

#############################
# Install PHP 7.3
#############################
if [[ "$PM" == "yum" ]]; then
    yum remove -y php73 || true
    yum install -y php73-fpm php73-mbstring php73-gd php73-cli php73-mcrypt php73-opcache php73-pdo php73-mysqlnd php73-zip
elif [[ "$PM" == "apt-get" ]]; then
    add-apt-repository ppa:ondrej/php -y
    apt-get update
    apt-get install -y \
  php8.4 \
  php8.4-fpm \
  php8.4-mbstring \
  php8.4-gd \
  php8.4-cli \
  php8.4-opcache \
  php8.4-pdo \
  php8.4-mysql \
  php8.4-zip
fi

#############################
# Install git
#############################
$PM install -y git

#############################
# Install composer
#############################
if [[ -z "$COMPOSER_CMD" ]]; then
    curl -sS https://getcomposer.org/installer | php
=======
#############################
#Install Apache(httpd24)
#############################
yum install -y mod24_ssl

#############################
#Install php (7.3)
#############################
yum remove -y php73
yum install -y php73-fpm php73-mbstring php73-gd php73-cli php73-mcrypt php73-opcache php73-pdo php73-mysqlnd php73-zip
yum install -y git --nogpgcheck

#############################
#Install composer
#############################
if [[ "" == "$COMPOSER_CMD" ]]
then
    curl -sS https://getcomposer.org/installer | sudo php
>>>>>>> bcddde5 (1)
    mv composer.phar /usr/local/bin/composer
    ln -s /usr/local/bin/composer /usr/bin/composer
fi

<<<<<<< HEAD
#############################
# Apache Config Files
#############################
rsync -azq "$CONF_DIR/apache/conf.d/" "$HTTPD_DIR/conf.d/"
rsync -azq "$CONF_DIR/apache/conf.modules.d/" "$HTTPD_DIR/conf.modules.d/"

#############################
# PHP Config
#############################
cp -f "$CONF_DIR/php/php-7.0.ini" /etc/php.ini

#############################
# PHP-FPM Config
#############################
cp -f "$CONF_DIR/php-fpm/$DEPLOYMENT_GROUP_NAME_ENV/www.conf" /etc/php-fpm.d/www.conf
=======
##################################################################


#Copy conf.d & conf.modules.d files
rsync -azq $CONF_DIR/apache/conf.d/ /etc/httpd/conf.d/
rsync -azq $CONF_DIR/apache/conf.modules.d/ /etc/httpd/conf.modules.d/

##################################################################

###########
#PHP
###########
cp -f $CONF_DIR/php/php-7.0.ini /etc/php-7.0.ini

##################################################################

###########
#PHP-FPM
###########
cp -f $CONF_DIR/php-fpm/$DEPLOYMENT_GROUP_NAME_ENV/www.conf /etc/php-fpm.d/www.conf

##################################################################
>>>>>>> bcddde5 (1)
