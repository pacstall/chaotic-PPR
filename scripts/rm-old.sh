#!/bin/bash

# Thanks https://askubuntu.com/a/250166
echo -e ":: SCANNING FOR OLD PACKAGES"
dpkg-scanpackages --arch amd64 "/home/pacstall/ppr-base/pool/" 2>&1 >/dev/null | grep -Po '((\/.*?deb)(?=.*?repeat;))|used that.*?\K(\/.*deb)' | xargs rm
