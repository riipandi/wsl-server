#!/usr/bin/env bash
set -e

if [[ ! $EUID -ne 0 ]]; then echo -e 'This script must be run as non-root user' ; exit 1 ; fi

# Set Git user information
echo
read -ep "Your Full Name     ? " fullname
read -ep "Your Email Address ? " mailaddr
git config --global user.name  "$fullname"
git config --global user.email "$mailaddr"
git config --global core.autocrlf input
echo

echo "Instaling Composer packages..."
composer global require hirak/prestissimo friendsofphp/php-cs-fixer laravel/installer wp-cli/wp-cli

# Add Yarn and Composer to path
echo "Configuring environment variables..."
if ! grep -q 'Composer' $HOME/.bashrc ; then
    touch "$HOME/.bashrc"
    {
        echo ''
        echo '# Composer and Yarn'
        echo 'export PATH=$PATH:$HOME/.config/composer/vendor/bin:$HOME/.yarn/bin'
        echo ''
    } >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
fi

echo "Instaling NPM packages..."
yarn global add expo-cli electron firebase-tools serve git-upload vsce gatsby next-express-bootstrap-boilerplate

# Add Golang to path
GOROOT="/usr/local/go"
GOPATH="/mnt/d/Workspace/Goland"
if [ -d "$GOROOT" ]; then
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
        source "$HOME/.bashrc"
        echo "GOROOT set to $GOROOT"
        echo "GOPATH set to $GOPATH"
    fi
fi

# SSH Keys
mkdir -p $HOME/.ssh ; chmod 0700 $_
touch $HOME/.ssh/id_rsa ; chmod 0600 $_
