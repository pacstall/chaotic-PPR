#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd /home/pacstall/ppr-base/

while inotifywait -e modify -e move -e create -e delete /home/pacstall/ppr-base/pool/main/; do
	# Clear old packages
	"$SCRIPT_DIR/rm-old.sh"
	# Continue to add packages
	echo -e ":: PACKAGE DIR HAS BEEN MODIFIED"
	dpkg-scanpackages --arch amd64 pool/ > "/home/pacstall/ppr-base/dists/pacstall/main/binary-amd64/Packages"
	cat "/home/pacstall/ppr-base/dists/pacstall/main/binary-amd64/Packages" | gzip -9 > "/home/pacstall/ppr-base/dists/pacstall/main/binary-amd64/Packages.gz"
	cd "/home/pacstall/ppr-base/dists/pacstall"
	echo -e ":: CREATING RELEASE"
	"$SCRIPT_DIR/generate-release.sh" > "Release"
	echo -e ":: SIGNING INRELEASE"
	cat "/home/pacstall/ppr-base/dists/pacstall/Release" | gpg --default-key "PPR" -abs --clearsign > "/home/pacstall/ppr-base/dists/pacstall/InRelease"
done
