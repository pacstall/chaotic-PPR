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

function check_overflow() {
  local package="${1}" repo="${2}" architecture="${3}" max="${4}" url="${5}" responses matches removes remove_ref
  mapfile -t responses < <(curl -s "${url}?q=${package}" | jq -r ".[]" | sort -r)
  for i in "${responses[@]}"; do
    [[ "${i}" == "P${architecture}"* ]] && matches+=("${i}")
  done
  if ((${#matches[@]}>=max)); then
    for i in "${!matches[@]}"; do
      ((i>=max-1)) && removes+=("${matches[${i}]}")
    done
  fi
  if [[ -n ${removes[*]} ]]; then
    printf -v remove_ref "'%s'," "${removes[@]}"
    echo "${remove_ref%,}"
  fi
}

check_overflow "${1}" "${2}" "${3}" "${4}" "${5}"
