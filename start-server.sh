#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

# Run server daemon in background

echo "Starting php5.6-fpm..."
service php5.6-fpm --full-restart

echo "Starting php7.2-fpm..."
service php7.2-fpm --full-restart

echo "Starting php7.3-fpm..."
service php7.3-fpm --full-restart

echo "Starting nginx..."
service nginx --full-restart

echo "Starting mysql server..."
service mysql --full-restart

echo "Starting postgresql server..."
service postgresql --full-restart

echo "Starting redis server..."
service redis-server --full-restart
