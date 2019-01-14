#!/usr/bin/env bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root!' ; exit 1 ; fi
#
# For more faster WSL I/O processing you can exlude this path from Windows Defender:
#  %USERPROFILE%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu18.04onWindows_79rhkp1fndgsc
#

PWD=$(dirname "$(readlink -f "$0")")

[[ -d "/mnt/d/" ]] && WORKSPACE="/mnt/d/Workspace" || WORKSPACE="/mnt/c/Workspace"

# Passwordless sudo and setup snippets
#---------------------------------------------------------------------------------------
perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers
chmod +x $PWD/snippets/* ; cp $PWD/snippets/* /usr/local/bin ; chown root: /usr/local/bin/*

# Keep packages up to date
#---------------------------------------------------------------------------------------
echo "Updating system packages ..."
COUNTRY=$(wget -qO- ipapi.co/json | grep '"country":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ $COUNTRY == "ID" ] ; then
    MIRROR="http://kartolo.sby.datautama.net.id/ubuntu"
elif [ $COUNTRY == "SG" ] ; then
    MIRROR="http://mirror.0x.sg/ubuntu"
else
    MIRROR="mirror://mirrors.ubuntu.com/mirrors.txt"
fi

MIRROR=$(echo $MIRROR | awk '{ gsub("[/]","\\/",$1); print $1 }')
{
    echo "deb MIRROR CODENAME main restricted universe multiverse"
    echo "deb MIRROR CODENAME-updates main restricted universe multiverse"
    echo "deb MIRROR CODENAME-security main restricted universe multiverse"
    echo "deb MIRROR CODENAME-proposed main restricted universe multiverse"
} > /etc/apt/sources.list
sed -i "s/MIRROR/$MIRROR/" /etc/apt/sources.list
sed -i "s/CODENAME/$(lsb_release -cs)/" /etc/apt/sources.list

# Install basic packages
#---------------------------------------------------------------------------------------
apt update ; apt full-upgrade -y
apt install -y apt-transport-https debconf-utils curl crudini pwgen s3cmd binutils
apt install -y dnsutils zip unzip bsdtar rsync screenfetch git

# Install Nginx + PHP-FPM + Python3
#---------------------------------------------------------------------------------------
echo "deb http://ppa.launchpad.net/ondrej/nginx/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/nginx.list
echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/sury-php.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com E5267A6C ; apt update

apt install -y php5.6 php{5.6,7.2,7.3}-{bcmath,cgi,cli,common,curl,fpm,gd,gmp,imap,intl,json,mbstring,mysql,opcache,pgsql,readline,sqlite3,xml,xmlrpc,zip,zip}
apt install -y php7.3-imagick php-pear composer gettext gamin mcrypt imagemagick nginx redis-server {python,python3}-{dev,pip,virtualenv} virtualenv gunicorn
pip install pipenv ; pip3 install pipenv

# Configuring Nginx
#---------------------------------------------------------------------------------------
[[ -d /var/www ]] || mkdir -p /var/www
[[ -d $WORKSPACE/Webdir ]] || mkdir -p $WORKSPACE/Webdir
curl -sL https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /etc/ssl/certs/chain.pem
curl -sL https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam-4096.pem
rm -fr /etc/nginx ; cp -r $PWD/nginx /etc/ ; service nginx restart
cp /etc/nginx/manifest/default.php /var/www/index.php
cp /etc/nginx/errpage/* /usr/share/nginx/html/

# Configure PHP-FPM
#---------------------------------------------------------------------------------------
find /etc/php/. -name 'php.ini' -exec bash -c 'crudini --set "$0" "PHP" "display_errors" "On"' {} \;
crudini --set /etc/php/5.6/fpm/pool.d/www.conf  'www' 'listen' '127.0.0.1:9056'
crudini --set /etc/php/7.2/fpm/pool.d/www.conf  'www' 'listen' '127.0.0.1:9072'
crudini --set /etc/php/7.3/fpm/pool.d/www.conf  'www' 'listen' '127.0.0.1:9073'

mkdir -p /run/php /var/run/php
service php5.6-fpm restart
service php7.2-fpm restart
service php7.3-fpm restart
service redis-server restart

# Set default PHP version
#---------------------------------------------------------------------------------------
update-alternatives --set php /usr/bin/php7.2 >/dev/null 2>&1
update-alternatives --set phar /usr/bin/phar7.2 >/dev/null 2>&1
update-alternatives --set phar.phar /usr/bin/phar.phar7.2 >/dev/null 2>&1
phpenmod curl imagick fileinfo ; phpdismod opcache

# Nodejs + Yarn
#---------------------------------------------------------------------------------------
echo "deb https://deb.nodesource.com/node_10.x `lsb_release -cs` main" > /etc/apt/sources.list.d/nodejs.list
echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
apt update ; apt install -y nodejs yarn

# phpMyAdmin
#---------------------------------------------------------------------------------------
[[ -d /var/www/myadmin ]] || mkdir -p /var/www/myadmin
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
#---------------------------------------------------------------------------------------
[[ -d /var/www/pgadmin ]] || mkdir -p /var/www/pgadmin
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

# Golang: install globally
#---------------------------------------------------------------------------------------
GOROOT="/usr/local/go"
GOPATH="$WORKSPACE/Goland"
GO_URL='https://dl.google.com/go/go[0-9\.]+\.linux-amd64.tar.gz'

if [[ -d "$GOROOT" ]]; then
    read -ep "There is a Go installation, do you want to replace it? [Y/n] " answer
    if [[ "${answer,,}" =~ ^(no|n)$ ]] ; then exit 1 ; fi
    echo "Removing previous Go installation ..."
    rm -fr "$GOROOT"
fi

echo "Finding latest version of Go for AMD64 ..."
dl_url="$(wget -qO- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1 )"
latest="$(echo $dl_url | grep -oP 'go[0-9\.]+' | grep -oP '[0-9\.]+' | head -c -2 )"

echo "Downloading latest Go for AMD64: ${latest}"
if [ -f "/tmp/go-${latest}" ] ; then
    echo "Found Go for AMD64 ${latest} in cache.."
    cp -r "/tmp/go-${latest}" "$GOROOT"
else
    wget -cqO- "${dl_url}" | tar xvz -C /tmp
    mv /tmp/go "/tmp/go-${latest}"
    cp -r "/tmp/go-${latest}" $GOROOT
fi
unset dl_url ; unset GO_URL

# Adding GOPATH to .bashrc
echo "Configuring environment variables ..."
if ! grep -q 'GOPATH' $HOME/.bashrc ; then
    touch "$HOME/.bashrc"
    {
        echo ''
        echo '# GOLANG'
        echo 'export GOROOT='$GOROOT
        echo 'export GOPATH='$GOPATH
        echo 'export GOBIN=$GOPATH/bin'
        echo 'export PATH=$PATH:$GOROOT/bin:$GOBIN'
        echo ''
    } >> "$HOME/.bashrc"
fi

echo "Configuring working directory ..."
if [[ ! -d "$GOPATH" ]]; then mkdir -p "$GOPATH" ; chmod 777 "$GOPATH" ; fi
mkdir -p "$GOPATH" "$GOPATH/src" "$GOPATH/pkg" "$GOPATH/bin" "$GOPATH/out"
chmod 777 "$GOPATH" "$GOPATH/src" "$GOPATH/pkg" "$GOPATH/bin" "$GOPATH/out"
echo "GOPATH set to $GOPATH" ; source "$HOME/.bashrc"

# Buffalo Framework
#---------------------------------------------------------------------------------------
echo "Downloading Buffalo Framework ..."
project="https://api.github.com/repos/gobuffalo/buffalo/releases/latest"
release=`curl -s $project | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
download_link=`curl -s $project | grep "browser_download_url" | grep $release | grep linux_amd64 | cut -d '"' -f 4`
wget -qO- $download_link | tar xvz -C /tmp
cp /tmp/buffalo-no-sqlite /usr/local/bin/buffalo
chmod +x /usr/local/bin/buffalo

# PostgreSQL
#---------------------------------------------------------------------------------------
read -ep "Do you want to install PostgreSQL 11 ?   [Y/n] " answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    echo "deb https://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && apt update
    apt install -y postgresql-{11,client-11} pgcli && service postgresql restart
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'secret'"
fi

# SSH server configuration
#---------------------------------------------------------------------------------------
sed -i "s|\("^PubkeyAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^PasswordAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^UsePrivilegeSeparation" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ListenAddress" * *\).*|\10.0.0.0|" /etc/ssh/sshd_config
sed -i "s|\("^PermitRootLogin" * *\).*|\1no|" /etc/ssh/sshd_config
sed -i "s/[#]*ListenAddress/ListenAddress/" /etc/ssh/sshd_config
sed -i "s/[#]*Port [0-9]*/Port 22/" /etc/ssh/sshd_config
service ssh --full-restart

# Setup SSH Key
#---------------------------------------------------------------------------------------
mkdir -p $HOME/.ssh ; chmod 0700 $_
touch $HOME/.ssh/id_rsa ; chmod 0600 $_
touch $HOME/.ssh/id_rsa.pub ; chmod 0600 $_
touch $HOME/.ssh/authorized_keys ; chmod 0600 $_

# runuser -l $ADMIN -c 'composer global require hirak/prestissimo laravel/installer wp-cli/wp-cli'
# runuser -l $ADMIN -c 'yarn global add ghost-cli@latest'

# Cleaning up
#---------------------------------------------------------------------------------------
apt full-upgrade -y ; apt autoremove -y ; apt clean
