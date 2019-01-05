#!/usr/bin/env bash

WORKING_PATH="/mnt/d/Workspace/Webdir"

# Check if running by root
if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

if [ -z "$1" ] ; then
    echo -e "\nPlease input the domain name."
    echo -e "\nExample: $(basename "$0") domain.test\n"
    exit 1
fi

# Validate existing vhost
if [[ -f "/etc/nginx/vhost.d/$1.conf" ]]; then
    echo -e "\nVirtualHost already exist...\n"
    exit 1
else
    cp /etc/nginx/manifest/vhost-php.cnf /etc/nginx/vhost.d/$1.conf
    sed -i "s/HOSTNAME/$1/" /etc/nginx/vhost.d/$1.conf
    mkdir -p $WORKING_PATH/$1/public
    chown -R www-data: $WORKING_PATH/$1
    chmod -R 0775 $WORKING_PATH/$1
fi

if [[ ! -f "$WORKING_PATH/$1/public/index.php" ]]; then
    cp /etc/nginx/manifest/default.tpl $WORKING_PATH/$1/public/index.php
fi

# Add domain to hosts file
if ! grep -q $1 /etc/hosts ; then echo "127.0.0.1 $1" >> /etc/hosts ; fi

service nginx --full-restart

echo -e "VirtualHost for $1 created..."
