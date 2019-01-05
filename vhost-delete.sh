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
    rm -f /etc/nginx/vhost.d/$1.conf
    if grep -q "$1" /etc/hosts ; then
        sed -i "s/127.0.0.1 $1//" /etc/hosts
    fi
    service nginx --full-restart
    echo "VirtualHost for $1 removed..."
else
    echo "VirtualHost $1 doesn't exists..."
fi
