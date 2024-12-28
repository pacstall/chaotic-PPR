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

get_tag() {
  local distro="${1}" architecture="${2}" USER_IMAGE TOKEN manifest tag
  USER_IMAGE="pacstall/${distro}"
  TOKEN="$(
    curl -s "https://ghcr.io/token?scope=repository:${USER_IMAGE}:pull" |\
    awk -F'"' '$0=$4'
  )"
 tag=$(curl -s -H "Authorization: Bearer ${TOKEN}" \
   -H "Accept: application/vnd.oci.image.index.v1+json" \
   "https://ghcr.io/v2/${USER_IMAGE}/manifests/latest" |\
   jq -r --arg arch "${architecture}" '.manifests[] |
   select(.platform.architecture == $arch) |
   .digest'
  )
  echo "${tag}"
}

contains() {
    local check ret=1
    local -n arra="${1:?No array passed to array.contains}"
    local input="${2:?No input given to array.contains}"
    for check in "${arra[@]}"; do
        if [[ ${check} == "${input}" ]]; then
            ret=0
        fi
    done
    return "${ret}"
}

packer() {
  shopt -s extglob
  local pkg="${1}" dist="${2}" arch="${3}" archarr target container archopts \
    BPurple='\033[1;35m' BLUE='\033[0;34m' CYAN='\033[0;36m' BGreen='\033[1;32m' NC='\033[0m' BOLD='\033[1m' BCyan='\033[1;36m'
  mapfile -t archopts < <(curl -fsSL https://pacstall.dev/api/packages/${1} | jq -r '.architectures[]')
  if contains archopts "arm64" || contains archopts "aarch64"; then
    archarr+=("arm64")
  fi
  if contains archopts "amd64" || contains archopts "x86_64"; then
    archarr+=("amd64")
  fi
  if contains archopts "all"; then
    archarr=("all")
  fi
  if contains archopts "any"; then
    archarr=("amd64" "arm64")
  fi
  if [[ ${arch} != @(aarch64|arm64|x86_64|amd64|all|any) ]]; then
    echo "${arch} is not a supported architecture."
    echo "Valid entries: arm64, aarch64, amd64, x86_64, all, any"
    exit 1
  fi
  if ! contains archarr "${arch}" && ! contains archarr "all"; then
    echo "${arch} is not a supported architecture by ${pkg}."
    exit 1
  fi
  if [[ ${dist} != @(main|debian-stable|debian-testing|debian-unstable|ubuntu-latest|ubuntu-rolling|ubuntu-devel) ]]; then
    echo "${dist} is not a supported distro."
    echo "Valid entries: main, debian-stable, debian-testing, debian-unstable, ubuntu-latest, ubuntu-rolling, ubuntu-devel"
    exit 1
  fi
  if [[ "${dist}" == "main" ]]; then
    dist="ubuntu-latest"
  fi
  if [[ ${arch} != "any" ]]; then
    archarr=("${arch}")
  fi
  for a in "${archarr[@]}"; do
    if [[ ${a} == "all" ]]; then
      target=":latest"
    else
      target="@$(get_tag "${dist}" "${a}")"
    fi
    docker run --net=host --privileged "ghcr.io/pacstall/${dist}${target}" bash -c "mkdir -p out && cd out && pacstall -PBINs ${pkg}" \
    && container="$(docker ps -lq)" \
    && docker cp "${container}":/home/pacstall/out/. . \
    && echo -e "[${BCyan}⌘${NC}] ${BOLD}PACK${NC}: deb for ${BPurple}${pkg}${NC}/${BLUE}${dist/-/:}${NC}/${CYAN}${a}${NC} built at ${BGreen}${PWD}${NC}" \
    && docker rm "${container}" &> /dev/null
  done
}

packer "${1}" "${2}" "${3}"
