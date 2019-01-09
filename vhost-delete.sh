#!/usr/bin/env bash

# Some validation
if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi
if [ -z "$1" ] ; then echo -e "\nYou forgotten domain name!\nEx: $(basename "$0") domain.test\n" ; exit 1 ; fi

# Validate existing vhost
if [[ -f "/etc/nginx/vhost.d/$1.conf" ]]; then
    rm -f /etc/nginx/vhost.d/$1.conf
    if grep -q "$1" /etc/hosts ; then
        sed -i "s/127.0.0.1 $1//" /etc/hosts
    fi
    service nginx reload
    if [[ -f "/etc/supervisor/conf.d/$1.conf" ]]; then
        rm -f /etc/supervisor/conf.d/$1.conf
        supervisorctl reread
        service supervisor restart
    fi
    echo " * VirtualHost $1 removed..."
else
    echo " * VirtualHost $1 doesn't exists..."
fi
