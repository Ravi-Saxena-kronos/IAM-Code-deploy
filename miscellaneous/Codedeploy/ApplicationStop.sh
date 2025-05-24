#!/bin/bash

IEPF_DIR="/var/www/html"
IEPF_BACKUP_DIR="/var/www/html_backup"

# Stop services
systemctl stop php8.3-fpm
systemctl stop apache2

# Remove old backup if it exists
if [ -d "$IEPF_BACKUP_DIR" ]; then
  rm -rf "$IEPF_BACKUP_DIR"
fi

# Move current to backup
mv "$IEPF_DIR" "$IEPF_BACKUP_DIR"
