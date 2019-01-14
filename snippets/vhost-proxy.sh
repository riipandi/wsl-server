#!/usr/bin/env bash

WORKING_PATH="/mnt/d/Workspace/Webdir"

# Some validation
if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi
if [[ -z "$1" || -z "$2" ]] ; then
    echo -e "\nPlease define domain and application name. Example: $(basename "$0") domain.test myapp\n"
    exit 1
fi

# Validate existing vhost
if [[ -f "/etc/nginx/vhost.d/$1.conf" ]]; then echo " * VirtualHost $1 already exist..." ; exit 1 ; fi

# Set application port
# echo -e "\nPort that already used:\n"
# ls /etc/nginx/vhost.d/ | cut -d '-' -f 1 | sed ':a;N;$!ba;s/\n/ /g'
echo && read -ep "Enter application port number : " -i "5800" APP_PORT

# Create virtualhost configuration file
if ! grep -q $1 /etc/hosts ; then echo "127.0.0.1 $1" >> /etc/hosts ; fi
cp /etc/nginx/manifest/vhost-proxy.cnf /etc/nginx/vhost.d/$1.conf
sed -i "s/APP_PORT/$APP_PORT/" /etc/nginx/vhost.d/$1.conf
sed -i "s/HOSTNAME/$1/" /etc/nginx/vhost.d/$1.conf

# Application directory
if [[ ! -d "$WORKING_PATH/$1" ]]; then
    mkdir -p $WORKING_PATH/$1
    chmod 0777 $WORKING_PATH/$1
    chown www-data: $WORKING_PATH/$1
fi

# Create default example application
if [[ ! -f "$WORKING_PATH/$1/default.py" ]]; then
    # Setup virtual env
    cp /etc/nginx/manifest/example.py $WORKING_PATH/$1/example.py
    cd $WORKING_PATH/$1 ; rm -rf .venv
    /usr/bin/virtualenv -qp python3 .venv --download
    $WORKING_PATH/$1/.venv/bin/pip install -q gunicorn falcon
    chown -R www-data: $WORKING_PATH/$1
    # {
    #     echo "description \"$1 process manager\""
    #     echo "start on runlevel [2345]"
    #     echo "stop on runlevel [016]"
    #     echo "respawn"
    #     echo "setuid www-data"
    #     echo "setgid www-data"
    #     echo "chdir $WORKING_PATH/$1"
    #     echo "exec .venv/bin/gunicorn -b 127.0.0.1:5801 example:api"
    # } > /etc/init/$2.conf
    # service $2 restart
fi

service nginx reload

echo " * VirtualHost $1 created..."
