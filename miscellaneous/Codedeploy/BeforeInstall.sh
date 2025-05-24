#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
apt-get update && apt-get install -y curl

apt-get install -y rsync

currentDir="$(dirname "$0")"
COMPOSER_CMD=$(command -v composer)
CONF_DIR="$currentDir/conf"
HTTPD_DIR="/etc/httpd"
DEPLOYMENT_GROUP_NAME_ENV=$(echo "$DEPLOYMENT_GROUP_NAME" | cut -d- -f1)

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
# Install PHP (7.3 or 8.3 depending on PM)
#############################

if [[ "$PM" == "yum" ]]; then
    echo "Detected package manager: yum (likely Amazon Linux or RHEL/CentOS)"
    yum remove -y php73 || true
    yum install -y \
        php73-fpm \
        php73-mbstring \
        php73-gd \
        php73-cli \
        php73-mcrypt \
        php73-opcache \
        php73-pdo \
        php73-mysqlnd \
        php73-zip

elif [[ "$PM" == "apt-get" ]]; then
    echo "Detected package manager: apt-get (likely Ubuntu/Debian)"
    apt-get update
    apt-get install -y software-properties-common lsb-release ca-certificates apt-transport-https

    # Add PHP 8.3 PPA only if not already added
    if ! grep -q "^deb .*.ondrej.*php" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        add-apt-repository ppa:ondrej/php -y
    fi

    apt-get update
    apt-get install -y \
        php8.3 \
        php8.3-fpm \
        php8.3-mbstring \
        php8.3-gd \
        php8.3-cli \
        php8.3-opcache \
        php8.3-pdo \
        php8.3-mysql \
        php8.3-zip
else
    echo "Unsupported package manager: $PM"
    exit 1
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
    mv composer.phar /usr/local/bin/composer
    ln -s /usr/local/bin/composer /usr/bin/composer
fi

apt-get install -y apache2

#############################
# Apache Config Files
#############################
rsync -azq "miscellaneous/Codedeploy/conf/apache/conf.d/" "/etc/apache2/conf-available/"
rsync -azq "miscellaneous/Codedeploy/conf/apache/conf.modules.d/" "/etc/apache2/mods-available/"

#############################
# PHP Config
#############################
cp -f "miscellaneous/Codedeploy/conf/php/php-7.0.ini" /etc/php.ini

#############################
# PHP-FPM Config
#############################
cp -f "miscellaneous/Codedeploy/php-fpm/$DEPLOYMENT_GROUP_NAME_ENV/www.conf" /etc/php-fpm.d/www.conf
echo "This is a message"
