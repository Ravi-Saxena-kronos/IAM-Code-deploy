#!/bin/bash

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
