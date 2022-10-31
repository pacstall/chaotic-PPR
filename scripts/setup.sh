#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [[ -z $PPR_BASE ]]; then
	echo "PPR_BASE not found!"
	exit 1
fi

if [[ -f "$PPR_BASE/.init" ]]; then
	cd "$PPR_BASE"
	python3 -m http.server
else
	cd "$PPR_BASE"
	"$SCRIPT_DIR/init.sh"
	"$SCRIPT_DIR/add-package.sh" neofetch
	"$SCRIPT_DIR/generate-pgp.sh"
	python3 -m http.server
fi
