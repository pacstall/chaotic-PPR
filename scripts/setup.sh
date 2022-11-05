#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [[ -f "/home/pacstall/ppr-base/.init" ]]; then
	cd "/home/pacstall/ppr-base/"
	#echo -e ":: Starting http server"
	#python3 -m http.server
	sleep infinity
else
	mkdir -p "/home/pacstall/ppr-base/pool/main"
	mkdir -p "/home/pacstall/ppr-base/dists/pacstall/main/binary-amd64"
	cd "/home/pacstall/ppr-base/"
	"$SCRIPT_DIR/init.sh"
	if ! [[ -f "/home/pacstall/ppr-base/default-packagelist" ]]; then
		echo "neofetch" > "/home/pacstall/ppr-base/default-packagelist"
	fi
	"$SCRIPT_DIR/add-package.sh" --populate
	"$SCRIPT_DIR/generate-pgp.sh"
	touch "/home/pacstall/ppr-base/.init"
	#echo -e ":: Starting http server"
	#python3 -m http.server
	sleep infinity
fi
