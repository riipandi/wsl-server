#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

# Kill the daemon

echo "Stopping php5.6-fpm..."
service php5.6-fpm start

echo "Stopping php7.2-fpm..."
service php7.2-fpm start

echo "Stopping php7.3-fpm..."
service php7.3-fpm start

echo "Stopping nginx..."
service nginx start

# echo "Stopping mysql server..."
# service mysql start

# echo "Stopping postgresql server..."
# service postgresql start

echo "Stopping redis server..."
service redis-server start
