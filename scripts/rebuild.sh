#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd "$PPR_BASE"

while inotifywait -e modify -e move -e create -e delete "$PPR_BASE/pool/"; do
	dpkg-scanpackages --arch amd64 pool/ > "$PPR_BASE/dists/pacstall/main/binary-amd64/Packages"
	cat "$PPR_BASE/dists/pacstall/main/binary-amd64/Packages" | gzip -9 > "$PPR_BASE/dists/pacstall/main/binary-amd64/Packages.gz"
	cd "$PPR_BASE/dists/pacstall"
	"$SCRIPT_DIR/generate-release.sh" > "Release"
done
