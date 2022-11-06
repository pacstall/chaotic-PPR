#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [[ -f "/home/pacstall/ppr-base/.init" ]]; then
	cd "/home/pacstall/ppr-base/"
	"$SCRIPT_DIR/wait.sh"
else
	mkdir -p "/home/pacstall/ppr-base/pool/main"
	mkdir -p "/home/pacstall/ppr-base/dists/pacstall/main/binary-amd64"
	cd "/home/pacstall/ppr-base/"
	if ! [[ -f "/home/pacstall/ppr-base/default-packagelist" ]]; then
		echo "neofetch" > "/home/pacstall/ppr-base/default-packagelist"
	fi
	"$SCRIPT_DIR/add-package.sh" --populate
	cat "/home/pacstall/ppr-base/dists/pacstall/Release" | gpg --default-key "PPR" -abs --clearsign > "/home/pacstall/ppr-base/dists/pacstall/InRelease"
	touch "/home/pacstall/ppr-base/.init"
	"$SCRIPT_DIR/wait.sh"
fi
