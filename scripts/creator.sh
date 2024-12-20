#!/usr/bin/env bash

LOCAL_PORT=8088
distrolist=("ubuntu-latest" "ubuntu-develop" "ubuntu-rolling" "debian-stable" "debian-testing" "debian-unstable")
archlist=("amd64" "arm64" "source")
mapfile -t pprlist < <(for i in "${distrolist[@]}"; do echo "{\"Component\": \"${i}\", \"Name\": \"ppr-${i}\"},"; done)
pprstring="${pprlist[@]}"
archstring="$(printf '"%s", ' "${archlist[@]}")"

# create
for i in "${distrolist[@]}"; do
  curl -X POST -H 'Content-Type: application/json' \
    --data "{\"Name\": \"ppr-${i}\", \"DefaultDistribution\": \"pacstall\", \"DefaultComponent\": \"${i}\"}" \
    http://localhost:"${LOCAL_PORT}"/api/repos
done

# publish
curl -X POST -H 'Content-Type: application/json' \
  --data "{\"SourceKind\": \"local\", \"Sources\": [${pprstring%,}], \"Architectures\": [${archstring%, }], \"Distribution\": \"pacstall\", \"Signing\": {\"Skip\": true}, \"MultiDist\": true}" \
  http://localhost:"${LOCAL_PORT}"/api/publish/pacstall
