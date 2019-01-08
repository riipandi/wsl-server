#!/usr/bin/env bash
set -e

##
# You have to run this script with sudo!
##

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

# If not defined
GVERSION="1.11.2"

if [[ ! -z $1 ]]; then GVERSION=$1 ; fi

GOFILE="go$GVERSION.linux-amd64.tar.gz"
GOPATH="/mnt/d/Workspace/Goland"
GOROOT="/usr/local/go"

if [[ -d "$GOROOT" ]]; then
    read -ep "There is a Go installation, do you want to replace it? [Y/n] " answer
    if [[ "${answer,,}" =~ ^(no|n)$ ]] ; then exit 1 ; fi
    echo "Removing previous Go installation..."
    rm -fr "$GOROOT"
fi

if [[ ! -d "$GOPATH" ]]; then
    mkdir -p "$GOPATH"
    chmod 777 "$GOPATH"
fi

mkdir -p "$GOROOT"
chmod 777 "$GOROOT"

echo "Downloading Golang files..."
wget -cqO- https://storage.googleapis.com/golang/$GOFILE | tar xvz -C /usr/local
if [ $? -ne 0 ]; then echo "Go download failed! Exiting." ;  exit 1 ; fi

# Adding GOPATH to .bashrc
echo "Configuring environment variables..."
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
    echo "GOROOT set to $GOROOT"
fi

echo "Configuring working directory..."
mkdir -p "$GOPATH" "$GOPATH/src" "$GOPATH/pkg" "$GOPATH/bin" "$GOPATH/out"
chmod 777 "$GOPATH" "$GOPATH/src" "$GOPATH/pkg" "$GOPATH/bin" "$GOPATH/out"
echo "GOPATH set to $GOPATH"
source "$HOME/.bashrc"

# Buffalo Framework
echo "Downloading Buffalo Framework..."
project="https://api.github.com/repos/gobuffalo/buffalo/releases/latest"
latest_release=`curl -s $project | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
download_link=`curl -s $project | grep "browser_download_url" | grep $latest_release | grep linux_amd64 | cut -d '"' -f 4`
wget -qO- $download_link | tar xvz -C /tmp
cp /tmp/buffalo-no-sqlite /usr/local/bin/buffalo
chmod +x /usr/local/bin/buffalo
