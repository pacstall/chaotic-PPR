#!/bin/bash

# Thanks https://askubuntu.com/a/250166
echo -e ":: SCANNING FOR OLD PACKAGES"
(
cd /home/pacstall/ppr-base/
# xargs -r prevents running if empty
dpkg-scanpackages --arch amd64 "pool/" 2>&1 >/dev/null | grep -Po '((\/.*?deb)(?=.*?repeat;))|used that.*?\K(\/.*deb)' | xargs -r rm -v
)
