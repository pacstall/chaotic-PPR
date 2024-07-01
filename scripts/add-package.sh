#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

function msg() {
	echo -e ":: $*"
}

if [[ $1 == '--populate' ]]; then
	readarray -t INPUT < "/home/pacstall/ppr-base/default-packagelist"
else
	INPUT=("${@:?No input given}")
fi

msg "Adding ${INPUT[*]}"

for pkg in "${INPUT[@]}"; do
	export BUILD_SITE="/tmp/chaotic-PPR/build/$pkg"
	if [[ -d $BUILD_SITE ]]; then
		msg "$BUILD_SITE exists! Skipping"
		continue
	else
		mkdir -p "$BUILD_SITE"
		cd "$BUILD_SITE"
	fi
	pacstall -D "$pkg"
	pacstall -BPI "$pkg.pacscript"
	sudo rm -rf "/tmp/pacstall-no-build/$pkg"
	msg "Built $pkg"
	mv *.deb "/home/pacstall/ppr-base/pool/main/"
	msg "Cleaning up build directory"
	rm "$pkg.pacscript"
	rm -r "$BUILD_SITE"
	cd "/home/pacstall/ppr-base"
	dpkg-scanpackages --arch amd64 pool/ > "/home/pacstall/ppr-base/dists/pacstall/main/binary-amd64/Packages"
	cat "/home/pacstall/ppr-base/dists/pacstall/main/binary-amd64/Packages" | gzip -9 > "/home/pacstall/ppr-base/dists/pacstall/main/binary-amd64/Packages.gz"
	msg "Updating Release file"
	cd "/home/pacstall/ppr-base/dists/pacstall"
	"$SCRIPT_DIR/generate-release.sh" > "Release"
done
