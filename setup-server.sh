#!/usr/bin/env bash
#
# For more faster WSL I/O processing you can exlude this path from Windows Defender:
#  %USERPROFILE%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu18.04onWindows_79rhkp1fndgsc
#

PWD=$(dirname "$(readlink -f "$0")")

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

# Development packages
apt install apt-transport-https curl git crudini pwgen s3cmd binutils dnsutils zip unzip bsdtar rsync screenfetch

# Basic configuration
perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers
sed -i "s|\("^PubkeyAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^PasswordAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^UsePrivilegeSeparation" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ListenAddress" * *\).*|\10.0.0.0|" /etc/ssh/sshd_config
sed -i "s|\("^PermitRootLogin" * *\).*|\1no|" /etc/ssh/sshd_config
sed -i "s/[#]*ListenAddress/ListenAddress/" /etc/ssh/sshd_config
sed -i "s/[#]*Port [0-9]*/Port 1022/" /etc/ssh/sshd_config
service ssh --full-restart

# Install MariaDB
echo "deb http://mirror.jaleco.com/mariadb/repo/10.3/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/mariadb.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C74CD1D8 && apt update

debconf-set-selections <<< "mysql-server mysql-server/root_password password secret"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password secret"
apt install mariadb-server mariadb-client
mysqladmin -uroot -psecret password "secret"
service mysql --full-restart

# PostgreSQL
echo "deb https://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list
curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt update ; apt -y install postgresql-{11,client-11}
service postgresql --full-restart
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'secret'"

# Install Nginx + PHP-FPM + Python3
echo "deb http://ppa.launchpad.net/ondrej/nginx/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/nginx.list
echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/sury-php.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com E5267A6C && apt update

apt install php5.6 php{5.6,7.2,7.3}-{bcmath,cgi,cli,common,curl,fpm,gd,gmp,imap,intl,json,mbstring,mysql,opcache,pgsql,readline,sqlite3,xml,xmlrpc,zip,zip}
apt install php7.3-imagick php-pear gettext gamin mcrypt imagemagick nginx
apt install python-{pip,pip-whl,virtualenv,dev} python3-virtualenv virtualenv

find /etc/php/. -name 'php.ini' -exec bash -c 'crudini --set "$0" "PHP" "display_errors" "Off"' {} \;
crudini --set /etc/php/5.6/fpm/php-fpm.conf  'www' 'listen' '127.0.0.1:9056'
crudini --set /etc/php/7.2/fpm/php-fpm.conf  'www' 'listen' '127.0.0.1:9072'
crudini --set /etc/php/7.3/fpm/php-fpm.conf  'www' 'listen' '127.0.0.1:9073'

# Configuring Nginx
curl -L# https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam-4096.pem
rm -fr /etc/nginx ; cp -r $PWD/nginx /etc/
cp /etc/nginx/manifest/default.tpl /var/www/index.php
service nginx --full-restart

# Redis Server
apt install redis-server
service redis-server --full-restart

# Nodejs + Yarn
echo "deb https://deb.nodesource.com/node_10.x `lsb_release -cs` main" > /etc/apt/sources.list.d/nodejs.list
curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
apt update && apt install nodejs yarn

# Golang + Buffalo Framework
bash <(curl -sLo- git.io/fh3dZ) 1.11.4

# phpMyAdmin
PMA_DIR="/var/www/myadmin"

if [ ! -d $PMA_DIR ]; then
curl -fsSL https://phpmyadmin.net/downloads/phpMyAdmin-latest-english.zip | bsdtar -xvf-
mv $PWD/phpMyAdmin*-english $PMA_DIR

cat > $PMA_DIR/config.inc.php <<EOF
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

chmod 0755 $PMA_DIR
find $PMA_DIR/. -type d -exec chmod 0777 {} \;
find $PMA_DIR/. -type f -exec chmod 0644 {} \;
chown -R www-data: $PMA_DIR
fi

# Development libraries: non-root user
yarn global add expo-cli electron firebase-tools serve git-upload vsce gatsby next-express-bootstrap-boilerplate
composer global require hirak/prestissimo friendsofphp/php-cs-fixer laravel/installer wp-cli/wp-cli
