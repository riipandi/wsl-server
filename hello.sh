#!/usr/bin/env bash
#
# For more faster WSL I/O processing you can exlude this path from Windows Defender:
#  %USERPROFILE%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu18.04onWindows_79rhkp1fndgsc
#

PWD=$(dirname "$(readlink -f "$0")")

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

# phpPgAdmin
project="https://api.github.com/repos/phppgadmin/phppgadmin/releases/latest"
latest_release=`curl -s $project | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
curl -fsSL https://github.com/phppgadmin/phppgadmin/archive/$latest_release.zip | bsdtar -xvf- -C /tmp
mv /tmp/phppgadmin-$latest_release /var/www/pgadmin

chmod 0755 /var/www/pgadmin
find /var/www/pgadmin/. -type d -exec chmod 0777 {} \;
find /var/www/pgadmin/. -type f -exec chmod 0644 {} \;
chown -R www-data: /var/www/pgadmin

cat > /var/www/pgadmin/conf/config.inc.php <<EOF
<?php
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
\$conf['min_password_length']           = 1;
\$conf['left_width']                    = 200;
\$conf['theme']                         = 'default';
\$conf['show_oids']                     = false;
\$conf['max_rows']                      = 30;
\$conf['max_chars']                     = 50;
\$conf['use_xhtml_strict']              = false;
\$conf['help_base']                     = 'http://www.postgresql.org/docs/%s/interactive/';
\$conf['ajax_refresh']                  = 3;
\$conf['plugins']                       = array();
\$conf['version']                       = 19;
?>
EOF