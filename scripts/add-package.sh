#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

function msg() {
	echo -e ":: $*"
}

if [[ -z $PPR_BASE ]]; then
	msg "PPR_BASE variable not found!"
	exit 1
fi

INPUT=("${@:?No input given}")

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
	msg "Built $pkg. Converting to valid deb name"
	( # So we don't have stray variables from source
	source "$pkg.pacscript"
	mv "${pkg}.deb" "${pkg}_${version}-1_amd64.deb"
	mv "${pkg}_${version}-1_amd64.deb" "$PPR_BASE/pool/main/"
	)
	msg "Cleaning up build directory"
	rm "$pkg.pacscript"
	rm -r "$BUILD_SITE"
	cd "$PPR_BASE"
	dpkg-scanpackages --arch amd64 pool/ > "$PPR_BASE/dists/stable/main/binary-amd64/Packages"
	cat "$PPR_BASE/dists/stable/main/binary-amd64/Packages" | gzip -9 > "$PPR_BASE/dists/stable/main/binary-amd64/Packages.gz"
	msg "Updating Release file"
	cd "$PPR_BASE/dists/stable"
	"$SCRIPT_DIR/generate-release.sh" > "Release"
done
