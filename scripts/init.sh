#!/bin/bash

if [[ -z $PPR_BASE ]]; then
	echo "PPR_BASE not found!"
	exit 1
fi

mkdir -p "$PPR_BASE/pool/main"
mkdir -p "$PPR_BASE/dists/stable/main/binary-amd64"
