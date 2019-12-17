#!/bin/bash

abort() {
    echo '
***************
*** ABORTED ***
***************
    ' >&2
    echo "An error occurred on line $1. Exiting..." >&2
    date -Iseconds >&2
    exit 1
}

trap 'abort $LINENO' ERR
set -e -o pipefail

quit() {
    trap : 0
    exit 0
}

# Asks if [Yn] if script shoud continue, otherwise exit 1
# $1: msg or nothing
# Example call 1: askContinueYn
# Example call 1: askContinueYn "Backup DB?"
askContinueYn() {
    if [[ $1 ]]; then
        msg="$1 "
    else
        msg=""
    fi

    # http://stackoverflow.com/questions/3231804/in-bash-how-to-add-are-you-sure-y-n-to-any-command-or-alias
    read -e -p "${msg}Continue? [Y/n] " response
    response=${response,,}    # tolower
    if [[ $response =~ ^(yes|y|)$ ]] ; then
        # echo ""
        # OK
        :
    else
        echo "Aborted"
        exit 1
    fi
}

# https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8

echo "Checking PHPMyAdmin version..."
# TAG=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
VERSION=$(curl -sL https://www.phpmyadmin.net/downloads/ | grep -e "<h2>phpMyAdmin .*</h2>" | perl -pe's%.*<h2>phpMyAdmin (\d+\.\d+\.\d+)</h2>.*%\1%')
echo

# read -e -p "Upgrade to version (e.g. 0.59.0): " VERSION

interactive=true

while test $# -gt 0; do
    case $1 in
        -h|--help)
            echo "Upgrade phpMyAdmin"
            echo
            echo "$0 [options]"
            echo
            echo "Options:"
            echo "-a                      Automatic mode"
            echo "-h, --help              Help"
            quit
            ;;
        -a)
            interactive=false
            shift
            ;;
    esac
done

BIN="public_html"
DOWNLOADS="."
DEST="phpmyadmin"

OLDVERSION=$(cat $BIN/$DEST/_VERSION.txt || echo "")
echo -e "\nUpgrade phpMyAdmin $VERSION\n"
echo -e "Current version: $OLDVERSION\n"

NAME="phpMyAdmin-$VERSION-all-languages"
GZ="$NAME.tar.gz"
cmd="wget --trust-server-names https://files.phpmyadmin.net/phpMyAdmin/$VERSION/phpMyAdmin-4.9.2-all-languages.tar.gz -O $DOWNLOADS/$GZ"
if $interactive ; then askContinueYn "$cmd"; fi
eval "$cmd"

cmd="echo -e '\nSize [Byte]'; stat --printf='%s\n' $DOWNLOADS/$GZ; echo -e '\nMD5'; md5sum $DOWNLOADS/$GZ; echo -e '\nSHA256'; sha256sum $DOWNLOADS/$GZ;"
if $interactive ; then askContinueYn "$cmd"; fi
eval "$cmd"

cmd="mkdir -p $BIN/$NAME; tar -xzf $DOWNLOADS/$GZ -C $BIN"
if $interactive ; then askContinueYn "$cmd"; fi
eval "$cmd"

cmd="echo $VERSION > $BIN/$NAME/_VERSION.txt; echo $VERSION > $BIN/$NAME/_VERSION_$VERSION.txt"
if $interactive ; then askContinueYn "$cmd"; fi
eval "$cmd"

cmd="[ -d $DEST.old ] && rm -r $DEST.old || echo 'No old dir to delete'"
if $interactive ; then askContinueYn "$cmd"; fi
eval "$cmd"

cmd="mv -iT $BIN/$DEST $DEST.old"
if $interactive ; then askContinueYn "$cmd"; fi
eval "$cmd"

cmd="mv -iT $BIN/$NAME $BIN/$DEST"
if $interactive ; then askContinueYn "$cmd"; fi
eval "$cmd"

cmd="cp -ir $DEST.old/.htaccess $DEST.old/.well-known $DEST.old/config.inc.php $BIN/$DEST"
if $interactive ; then askContinueYn "$cmd"; fi
eval "$cmd"

cmd="rm $DOWNLOADS/$GZ"
if $interactive ; then askContinueYn "$cmd"; fi
eval "$cmd"

echo -e "\nUpdate done!"

quit
