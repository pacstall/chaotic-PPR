#!/usr/bin/env bash
#     ____                  __        ____
#    / __ \____ ___________/ /_____ _/ / /
#   / /_/ / __ `/ ___/ ___/ __/ __ `/ / /
#  / ____/ /_/ / /__(__  ) /_/ /_/ / / /
# /_/    \__,_/\___/____/\__/\__,_/_/_/
#
# Copyright (C) 2020-present
#
# This file is part of Pacstall
#
# Pacstall is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License
#
# Pacstall is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Pacstall. If not, see <https://www.gnu.org/licenses/>.

APTLY_PORT="${1:?need PORT}"
distrolist=("main" "ubuntu-latest" "ubuntu-develop" "ubuntu-rolling" "debian-stable" "debian-testing" "debian-unstable")
archlist=("amd64" "arm64" "source")
mapfile -t pprlist < <(for i in "${distrolist[@]}"; do echo "{\"Component\": \"${i}\", \"Name\": \"ppr-${i}\"},"; done)
pprstring="${pprlist[@]}"
archstring="$(printf '"%s", ' "${archlist[@]}")"

# create
for i in "${distrolist[@]}"; do
  curl -X POST -H 'Content-Type: application/json' \
    --data "{\"Name\": \"ppr-${i}\", \"DefaultDistribution\": \"pacstall\", \"DefaultComponent\": \"${i}\"}" \
    http://localhost:"${APTLY_PORT}"/api/repos
done

# publish
curl -X POST -H 'Content-Type: application/json' \
  --data "{\"SourceKind\": \"local\", \"Sources\": [${pprstring%,}], \"Architectures\": [${archstring%, }], \"Distribution\": \"pacstall\", \"Signing\": {\"Skip\": true}, \"MultiDist\": true}" \
  http://localhost:"${APTLY_PORT}"/api/publish/pacstall
