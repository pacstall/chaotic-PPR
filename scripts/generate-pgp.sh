#!/bin/bash

echo "%echo Generating PGP key
Key-Type: RSA
Key-Length: 4096
Name-Real: PPR 
Name-Email: pacstall@pm.me
Expire-Date: 0
%no-ask-passphrase
%no-protection
%commit" > /tmp/ppr-pgp-key.batch

gpg --import /var/gpg/private-ppr.txt
gpg --import /home/pacstall/ppr-base/ppr.pub
cat "/home/pacstall/ppr-base/dists/pacstall/Release" | gpg --default-key "PPR" -abs --clearsign > "/home/pacstall/ppr-base/dists/pacstall/InRelease"
