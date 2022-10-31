#!/bin/bash

if [[ -z $PPR_BASE ]]; then
	echo "PPR_BASE not found!"
	exit 1
fi

echo "%echo Generating PGP key
Key-Type: RSA
Key-Length: 4096
Name-Real: PPR 
Name-Email: pacstall@pm.me
Expire-Date: 0
%no-ask-passphrase
%no-protection
%commit" > /tmp/ppr-pgp-key.batch

#mkdir -p "$HOME/.ppr"
#export GNUPGHOME="$(mktemp -d $HOME/.ppr/pgpkeys-XXXXXX)"
#gpg --no-tty --batch --gen-key /tmp/ppr-pgp-key.batch
#gpg --armor --export "PPR" > "$PPR_BASE/ppr.pub"
#gpg --armor --export-secret-keys "PPR" > /tmp/pgp-key.private
#gpg --import /tmp/pgp-key.private
gpg --import /var/gpg/private-ppr.txt
gpg --import /home/pacstall/ppr-base/ppr.pub
#rm /tmp/pgp-key.private
cat "$PPR_BASE/dists/pacstall/Release" | gpg --default-key "PPR" -abs --clearsign > "$PPR_BASE/dists/pacstall/InRelease"
