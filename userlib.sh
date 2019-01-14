#!/usr/bin/env bash
if [[ ! $EUID -ne 0 ]]; then echo -e 'Please do NOT run this script with sudo, run it as your own user!' ; exit 1 ; fi

[[ -d /mnt/d/ ]] && WORKSPACE="/mnt/d/Workspace" || WORKSPACE="/mnt/c/Workspace"

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
yarn global add eslint firebase-tools serve gatsby ghost-cli@latest

# Add Golang to path
GOROOT="/usr/local/go"
GOPATH="$WORKSPACE/Goland"
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

# Setup SSH Key
# ----------------------------------------------------------------------------------
mkdir -p $HOME/.ssh ; chmod 0700 $_
touch $HOME/.ssh/id_rsa ; chmod 0600 $_
touch $HOME/.ssh/id_rsa.pub ; chmod 0600 $_
touch $HOME/.ssh/authorized_keys ; chmod 0600 $_
