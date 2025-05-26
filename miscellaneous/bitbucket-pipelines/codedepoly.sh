#!/bin/bash

# Skip deployment if commit message contains "skip cd"
if [[ $LAST_COMMIT_MESSAGE == *"skip cd"* ]]; then
  echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
  echo "SKIPPING CODEDEPLOY"
  echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
  exit 0
fi

echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
echo "Zipping of the code to application.zip is already done in Prerequisite Step"
echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
echo "Pushing application.zip to S3 bucket..."
echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"

NOW=$(date +"%Y%m%d%H%M%S")
BUCKET_KEY="$APPLICATION_NAME/$NOW-bitbucket_builds.zip"
aws s3 cp /tmp/artifact.zip "s3://my-webr1/$BUCKET_KEY"
echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
echo "Creating CodeDeploy Deployment"
echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"

deploy_groups=()

if [ "$BITBUCKET_BRANCH" == "master" ]; then
  deploy_groups=("code-deploy-group")
elif [ "$BITBUCKET_BRANCH" == "staging" ]; then
  deploy_groups=("code-deploy-staging-group")
fi

if [ ${#deploy_groups[@]} -eq 0 ]; then
  echo "❌ No deployment group matched for branch: $BITBUCKET_BRANCH"
  exit 1
fi

for deploy_group in "${deploy_groups[@]}"; do
  echo "Creating deployment for: $deploy_group"
  aws deploy create-deployment \
    --application-name "$APPLICATION_NAME" \
    --deployment-group-name "$deploy_group" \
    --s3-location bucket="$S3_BUCKET",key="$BUCKET_KEY",bundleType=zip \
    --deployment-config-name "$DEPLOYMENT_CONFIG" \
    --description "New deployment from BitBucket Pipeline" \
    --ignore-application-stop-failures
done




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



HTTPD_DIR="/etc/httpd"
IEPF_DIR="/var/www/html"
IEPF_BACKUP_DIR="/var/www/html_old"
DEPLOYMENT_GROUP_NAME_ENV=$(echo "$DEPLOYMENT_GROUP_NAME" | cut -d- -f1)
S3_BUCKET="my-webr1"

COMPOSER=$(which composer)

# Yii2 Composer Assets Plugin
echo "START: Composer Assets Plugin:" `date +'%H:%M:%S'`
$COMPOSER config --global repo.packagist composer https://packagist.org
$COMPOSER global require "fxp/composer-asset-plugin:^1.3.1" --prefer-dist
echo "END: Composer Assets Plugin:" `date +'%H:%M:%S'`

cd "$IEPF_DIR"

# Permissions & directories
echo "START: Create Directories & fix permissions:" `date +'%H:%M:%S'`

mkdir -p frontend/web/uploads/temp backend/web/uploads/temp

chown apache \
    api/runtime api/web/assets \
    backend/runtime backend/web/assets \
    console/runtime \
    frontend/runtime frontend/web/assets frontend/web/uploads frontend/web/uploads/temp \
    backend/web/uploads backend/web/uploads/temp

echo "END: Create Directories & fix permissions:" `date +'%H:%M:%S'`

# Vendor sync from backup if missing
if [ ! -d "$IEPF_DIR/vendor" ]; then
    if [ -d "$IEPF_BACKUP_DIR/vendor" ]; then
        echo "START: Syncing vendor from previous installation:" `date +'%H:%M:%S'`
        rsync -azqp "$IEPF_BACKUP_DIR/vendor/" "$IEPF_DIR/vendor/"
        echo "END: Syncing vendor from previous installation:" `date +'%H:%M:%S'`
    fi
fi

# Composer install
echo "START: Composer Update:" `date +'%H:%M:%S'`
$COMPOSER install --no-interaction --optimize-autoloader --no-progress -d "$IEPF_DIR"
echo "END: Composer Update:" `date +'%H:%M:%S'`

# Download config from S3
aws s3 cp "s3://$S3_BUCKET/Config/" . --recursive --quiet

# DB Migration
echo "START: DB migration"
MIGRATION_LOCK_FILE="/tmp/migration.lock"
if [ ! -f "$MIGRATION_LOCK_FILE" ]; then
    RANDOM_NUMBER=$RANDOM
    echo $RANDOM_NUMBER > $MIGRATION_LOCK_FILE
    sleep 2
    if [ "$(cat $MIGRATION_LOCK_FILE)" == "$RANDOM_NUMBER" ]; then
        echo "RUNNING: DB migration"
        php yii migrate --interactive=0
        rm -f "$MIGRATION_LOCK_FILE"
    fi
fi
echo "END: DB migration"
