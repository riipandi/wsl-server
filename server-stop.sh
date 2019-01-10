#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

# Kill the daemon

echo "Stopping php5.6-fpm..."
service php5.6-fpm stop

echo "Stopping php7.2-fpm..."
service php7.2-fpm stop

echo "Stopping php7.3-fpm..."
service php7.3-fpm stop

echo "Stopping nginx..."
service nginx stop

echo "Stopping mysql server..."
service mysql stop

echo "Stopping postgresql server..."
service postgresql stop

echo "Stopping redis server..."
service redis-server stop
