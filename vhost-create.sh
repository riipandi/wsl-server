#!/usr/bin/env bash

WORKING_PATH="/mnt/d/Workspace/Webdir"

# Some validation
if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi
if [ -z "$1" ] ; then echo -e "\nYou forgotten domain name!\nExample: $(basename "$0") domain.test\n" ; exit 1 ; fi

# Validate existing vhost
if [[ -f "/etc/nginx/vhost.d/$1.conf" ]]; then echo " * VirtualHost $1 already exist..." ; exit 1 ; fi

# Create virtualhost configuration file
cp /etc/nginx/manifest/vhost-php.cnf /etc/nginx/vhost.d/$1.conf
sed -i "s/HOSTNAME/$1/" /etc/nginx/vhost.d/$1.conf

# Create directory
if [[ ! -d "$WORKING_PATH/$1/public" ]]; then
    mkdir -p $WORKING_PATH/$1/public
    chown -R www-data: $WORKING_PATH/$1
    chmod -R 0775 $WORKING_PATH/$1
fi

if [[ ! -f "$WORKING_PATH/$1/public/index.php" ]]; then
    cp /etc/nginx/manifest/default.php $WORKING_PATH/$1/public/index.php
fi

# Add domain to hosts file
if ! grep -q $1 /etc/hosts ; then echo "127.0.0.1 $1" >> /etc/hosts ; fi

service nginx reload

echo " * VirtualHost $1 created..."
