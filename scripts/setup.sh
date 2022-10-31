#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [[ -z $PPR_BASE ]]; then
	echo "PPR_BASE not found!"
	exit 1
fi

if [[ -f "$PPR_BASE/.init" ]]; then
	cd "$PPR_BASE"
	echo -e ":: Starting http server"
	python3 -m http.server
else
	cd "$PPR_BASE"
	"$SCRIPT_DIR/init.sh"
	if ! [[ -f "$PPR_BASE/default-packagelist" ]]; then
		echo "neofetch" > "$PPR_BASE/default-packagelist"
	fi
	"$SCRIPT_DIR/add-package.sh" --populate
	"$SCRIPT_DIR/generate-pgp.sh"
	touch "$PPR_BASE/.init"
	echo -e ":: Starting http server"
	python3 -m http.server
fi
