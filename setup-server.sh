#!/usr/bin/env bash
#
# For more faster WSL I/O processing you can exlude this path from Windows Defender:
#  %USERPROFILE%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu18.04onWindows_79rhkp1fndgsc
#

PWD=$(dirname "$(readlink -f "$0")")

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

read -ep "Do you want to change repository mirror? [Y/n] " answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
  cat $PWD/sources.list > /etc/apt/sources.list
fi

# Development packages
apt update ; apt full-upgrade -y
apt install -y apt-transport-https debconf-utils curl git crudini pwgen s3cmd binutils
apt install -y dnsutils zip unzip bsdtar rsync screenfetch

# Basic configuration
perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers
sed -i "s|\("^PubkeyAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^PasswordAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^UsePrivilegeSeparation" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ListenAddress" * *\).*|\10.0.0.0|" /etc/ssh/sshd_config
sed -i "s|\("^PermitRootLogin" * *\).*|\1no|" /etc/ssh/sshd_config
sed -i "s/[#]*ListenAddress/ListenAddress/" /etc/ssh/sshd_config
sed -i "s/[#]*Port [0-9]*/Port 22/" /etc/ssh/sshd_config
service ssh --full-restart

# MySQL 8.0
echo "deb http://repo.mysql.com/apt/ubuntu/ `lsb_release -cs` mysql-8.0" > /etc/apt/sources.list.d/mysql.list
echo "deb http://repo.mysql.com/apt/ubuntu/ `lsb_release -cs` mysql-tools" >> /etc/apt/sources.list.d/mysql.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 5072E1F5 && apt update

debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password secret"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password secret"
debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)"
debconf-set-selections <<< "mysql-community-server mysql-community-server/remove-data-dir boolean false"
apt install -y mysql-server mysql-client mycli ; usermod -d /var/lib/mysql/ mysql ; systemctl disable mysql
cp $PWD/service-mysql.sh /etc/init.d/mysql ; chmod +x /etc/init.d/mysql

rm -f /etc/mysql/mysql.conf.d/default-auth-override.cnf
crudini --set /etc/mysql/mysql.conf.d/mysqld.cnf 'mysqld' 'default-authentication-plugin' 'mysql_native_password'
crudini --set /etc/mysql/mysql.conf.d/mysqld.cnf 'mysqld' 'innodb_use_native_aio' '0'
crudini --set /etc/mysql/mysql.conf.d/mysqld.cnf 'mysqld' 'bind-address' '127.0.0.1'
crudini --set /etc/mysql/mysql.conf.d/mysqld.cnf 'mysqld' 'port' '3306'
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'host' '127.0.0.1'
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'port' '3306'
service mysql restart ; mysql -uroot -psecret -e "drop database if exists test;"

# PostgreSQL
echo "deb https://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list
curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && apt update
apt install -y postgresql-{11,client-11} pgcli
service postgresql --full-restart
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'secret'"

# Install Nginx + PHP-FPM + Python3
echo "deb http://ppa.launchpad.net/ondrej/nginx/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/nginx.list
echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/sury-php.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com E5267A6C && apt update

apt install -y php5.6 php{5.6,7.2,7.3}-{bcmath,cgi,cli,common,curl,fpm,gd,gmp,imap,intl,json,mbstring,mysql,opcache,pgsql,readline,sqlite3,xml,xmlrpc,zip,zip}
apt install -y php7.3-imagick php-pear composer gettext gamin mcrypt imagemagick nginx redis-server {python,python3}-{dev,pip,virtualenv}
apt install -y python-pip-whl virtualenv gunicorn
pip install pipenv ; pip3 install pipenv
service redis-server --full-restart

find /etc/php/. -name 'php.ini' -exec bash -c 'crudini --set "$0" "PHP" "display_errors" "On"' {} \;
crudini --set /etc/php/5.6/fpm/pool.d/www.conf  'www' 'listen' '127.0.0.1:9056'
crudini --set /etc/php/7.2/fpm/pool.d/www.conf  'www' 'listen' '127.0.0.1:9072'
crudini --set /etc/php/7.3/fpm/pool.d/www.conf  'www' 'listen' '127.0.0.1:9073'

if [ ! -d /run/php ]; then mkdir -p /run/php ; fi
if [ ! -d /var/run/php ]; then mkdir -p /var/run/php ; fi

service php5.6-fpm restart
service php7.2-fpm restart
service php7.3-fpm restart

# Configuring Nginx
if [ ! -d /mnt/d/Workspace/Webdir ]; then mkdir -p /mnt/d/Workspace/Webdir ; fi
curl -sL https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /etc/ssl/certs/chain.pem
curl -sL https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam-4096.pem
rm -fr /etc/nginx ; cp -r $PWD/nginx /etc/ ; service nginx --full-restart
cp /etc/nginx/manifest/default.php /var/www/index.php

# Nodejs + Yarn
echo "deb https://deb.nodesource.com/node_10.x `lsb_release -cs` main" > /etc/apt/sources.list.d/nodejs.list
curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
apt update ; apt full-upgrade -y ; apt install -y nodejs yarn

# phpMyAdmin
if [ -d /var/www/myadmin ]; then rm -fr /var/www/myadmin ; fi
curl -fsSL https://phpmyadmin.net/downloads/phpMyAdmin-latest-english.zip | bsdtar -xvf-
mv $PWD/phpMyAdmin*-english /var/www/myadmin
cat > /var/www/myadmin/config.inc.php <<EOF
<?php
\$cfg['blowfish_secret'] = '`openssl rand -hex 16`';
\$i = 0; \$i++;
\$cfg['Servers'][\$i]['auth_type']       = 'cookie';
\$cfg['Servers'][\$i]['host']            = '127.0.0.1';
\$cfg['Servers'][\$i]['connect_type']    = 'tcp';
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['Servers'][\$i]['hide_db']         = '^(information_schema|performance_schema|mysql|phpmyadmin|sys)\$';
\$cfg['MaxRows']                         = 100;
\$cfg['SendErrorReports']                = 'never';
\$cfg['ShowDatabasesNavigationAsTree']   = false;
EOF
chmod 0755 /var/www/myadmin
find /var/www/myadmin/. -type d -exec chmod 0777 {} \;
find /var/www/myadmin/. -type f -exec chmod 0644 {} \;
chown -R www-data: /var/www/myadmin

# phpPgAdmin
if [ -d /var/www/pgadmin ]; then rm -fr /var/www/pgadmin ; fi
project="https://api.github.com/repos/phppgadmin/phppgadmin/releases/latest"
latest_release=`curl -s $project | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
curl -fsSL https://github.com/phppgadmin/phppgadmin/archive/$latest_release.zip | bsdtar -xvf- -C /tmp
mv /tmp/phppgadmin-$latest_release /var/www/pgadmin
cat > /var/www/pgadmin/conf/config.inc.php <<EOF
<?php @ini_set('display_errors', '0');
\$conf['servers'][0]['desc']            = 'PostgreSQL';
\$conf['servers'][0]['host']            = '127.0.0.1';
\$conf['servers'][0]['port']            = 5432;
\$conf['servers'][0]['sslmode']         = 'allow';
\$conf['servers'][0]['defaultdb']       = 'template1';
\$conf['servers'][0]['pg_dump_path']    = '/usr/bin/pg_dump';
\$conf['servers'][0]['pg_dumpall_path'] = '/usr/bin/pg_dumpall';
\$conf['default_lang']                  = 'auto';
\$conf['autocomplete']                  = 'default on';
\$conf['extra_login_security']          = false;
\$conf['owned_only']                    = false;
\$conf['show_comments']                 = true;
\$conf['show_advanced']                 = false;
\$conf['show_system']                   = false;
\$conf['min_password_length']           = 8;
\$conf['left_width']                    = 260;
\$conf['theme']                         = 'default';
\$conf['show_oids']                     = false;
\$conf['max_rows']                      = 30;
\$conf['max_chars']                     = 50;
\$conf['use_xhtml_strict']              = false;
\$conf['ajax_refresh']                  = 3;
\$conf['plugins']                       = array();
\$conf['version']                       = 19;
EOF
chmod 0755 /var/www/pgadmin
find /var/www/pgadmin/. -type d -exec chmod 0777 {} \;
find /var/www/pgadmin/. -type f -exec chmod 0644 {} \;
chown -R www-data: /var/www/pgadmin

# Set default PHP version
update-alternatives --set php /usr/bin/php7.2 >/dev/null 2>&1
update-alternatives --set phar /usr/bin/phar7.2 >/dev/null 2>&1
update-alternatives --set phar.phar /usr/bin/phar.phar7.2 >/dev/null 2>&1
phpenmod curl imagick fileinfo ; phpdismod opcache

# Golang: install globally
bash $PWD/setup-golang.sh 1.11.4

# Copy snippets to local bin
cp $PWD/start-server.sh /usr/local/bin/wsld-restart
cp $PWD/stop-server.sh /usr/local/bin/wsld-stop
cp $PWD/vhost-create.sh /usr/local/bin/vc
cp $PWD/vhost-delete.sh /usr/local/bin/vd
cp $PWD/vhost-proxy.sh /usr/local/bin/vd
chown root: /usr/local/bin/*

# Setup SSH Key
mkdir -p $HOME/.ssh ; chmod 0700 $_
touch $HOME/.ssh/id_rsa ; chmod 0600 $_
touch $HOME/.ssh/authorized_keys ; chmod 0600 $_

# Cleaning up
apt autoremove -y
apt clean

