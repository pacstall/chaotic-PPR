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

### CONSTANTS ###

LOGO="
░█▀▀░█░█░█▀█░█▀█░▀█▀░▀█▀░█▀▀░░░█▀█░█▀█░█▀▄
░█░░░█▀█░█▀█░█░█░░█░░░█░░█░░░░░█▀▀░█▀▀░█▀▄
░▀▀▀░▀░▀░▀░▀░▀▀▀░░▀░░▀▀▀░▀▀▀░░░▀░░░▀░░░▀░▀"

# ++ for every step in install.
STEPS=4

# Components available.
PPR_COMPONENTS=(
    "debian-stable"
    "debian-testing"
    "debian-unstable"
    "ubuntu-latest"
    "ubuntu-rolling"
    "ubuntu-develop"
)

# Available architectures.
PPR_ARCHITECTURES=(
    "amd64"
    "arm64"
)

# Colors.
BOLD=$'\033[1m'
NC=$'\033[0m'
BPurple=$'\033[1;35m'
BGreen=$'\033[1;32m'
BYellow=$'\033[1;33m'
UBORANGE=$'\e[1m\e[38;5;166m'
DEBRED=$'\e[1m\e[38;5;197m'
PACCYAN=$'\e[38;5;30m'
PACYELLOW=$'\e[38;5;214m'
RED=$'\033[0;31m'
BRed=$'\033[1;31m'

### FUNCTIONS ###

function catch() {
    echo -e "\n${BOLD}[${BRed}ERROR${NC}${BOLD}]:${NC} Installation failed, exiting script..."
    exit 1
}

function array.contains() {
    local check
    local -n arra="${1:?No array passed to array.contains}"
    local input="${2:?No input given to array.contains}"
    for check in "${arra[@]}"; do
        if [[ ${check} == "${input}" ]]; then
            return 0
        fi
    done
    return 1
}

function download_stdout() {
    local dl_link="${1}"
    if type wget &> /dev/null; then
        wget -qO - "${dl_link}"
    elif type curl &> /dev/null; then
        curl -s "${dl_link}"
    fi
}

function step() {
    local step_num="${1:?No step number passed}"
    local title="${2:?No step title passsed}"
    echo -e "${BOLD}[${NC}${BPurple}STEP${NC} ${step_num}/${STEPS}${BOLD}]${NC}: ${BOLD}${title}${NC}"
}

function decide_archs() {
    local arch farch questiono enableable_archs
    read -a arch < <(dpkg --print-architecture)
    mapfile -t farch < <(dpkg --print-foreign-architectures)
    read -rp "Do you want foreign architectures enabled? [${BGreen}Y${NC}/${RED}n${NC}]: "
    questiono="${REPLY:0:1}"
    if [[ -z "${questiono}" ]] || [[ "${questiono,,}" == 'y' ]]; then
        [[ -n ${farch[*]} ]] && arch+=("${farch[@]}")
    fi

    for i in "${arch[@]}"; do
        if array.contains "PPR_ARCHITECTURES" "${i}"; then
            enableable_archs+=("${i}")
        fi
    done

    if ((${#enableable_archs[@]} == 0)); then
        echo >&2 "No valid architectures available for the PPR which supports: '${PPR_ARCHITECTURES[*]}'"
        catch
    fi

    printf -v joined_archs '%s,' "${enableable_archs[@]}"
    export joined_archs
}

function decide_components() {
    local distro distro_id available_components
    while IFS='=' read -r key value; do
      case "${key}" in
        "DEBIAN_CODENAME") distro="debian" ;;
        "UBUNTU_CODENAME") distro="ubuntu" ;;
        "ID") distro_id="${value//\"/}" ;;
      esac
    done < /etc/os-release
    [[ -z ${distro} ]] && distro="${distro_id}"

    for i in "${PPR_COMPONENTS[@]}"; do
        if [[ "${i}" == "${distro}-"* ]]; then
            available_components+=("${i}")
        fi
    done
    [[ -z ${available_components[*]} ]] && available_components=("${PPR_COMPONENTS[@]}")

    echo -e "Component explanation:\n\n${BGreen}Legend${NC}\n------\n\nIf you are unsure which version to go with, select one marked with [${BYellow}*${NC}]\n"

    ub_distros="${BOLD}ubuntu-latest${NC}: Current LTS release of Ubuntu [${BYellow}*${NC}]\n${BOLD}ubuntu-rolling${NC}: Latest point release\n${BOLD}ubuntu-develop${NC}: Ubuntu using devel repos"

    deb_distros="${BOLD}debian-stable${NC}: Current release of Debian [${BYellow}*${NC}]\n${BOLD}debian-testing${NC}: Next upcoming release\n${BOLD}debian-unstable${NC}: Debian using sid repos"

    if [[ "${distro}" == *"ubuntu"* ]]; then
      echo -e "${UBORANGE}Ubuntu${NC}\n------\n\n${ub_distros}\n"
    elif [[ "${distro}" == *"debian"* ]]; then
      echo -e "${DEBRED}Debian${NC}\n------\n\n${deb_distros}\n"
    else
      echo -e "${DEBRED}Debian${NC}\n------\n\n${deb_distros}\n"
      echo -e "${UBORANGE}Ubuntu${NC}\n------\n\n${ub_distros}\n"
    fi

    chosen_components=("main")

    select chosen in "${available_components[@]}"; do
        case "${chosen}" in
            "ubuntu-latest") chosen_components+=("ubuntu-latest"); break ;;
            "ubuntu-rolling") chosen_components+=("ubuntu-rolling"); break ;;
            "ubuntu-develop") chosen_components+=("ubuntu-develop"); break ;;
            "debian-stable") chosen_components+=("debian-stable"); break ;;
            "debian-testing") chosen_components+=("debian-stable"); break ;;
            "debian-unstable") chosen_components+=("debian-unstable"); break ;;
            *) echo "Please choose a valid option" ;;
        esac
    done
    export chosen_components
}

### SCRIPT ###

echo -e "${PACCYAN}${LOGO}${NC}\n"
printf "%0.s${PACYELLOW}-${NC}" {0..41}
echo -e "\n"

step 1 "Deciding suggested architecture(s)"
decide_archs

step 2 "Deciding default components"
decide_components

step 3 "Downloading keyring to '/usr/share/keyrings/ppr-keyring.gpg'"
download_stdout https://ppr.pacstall.dev/ppr-public-key.asc | sudo gpg --dearmor -o /usr/share/keyrings/ppr-keyring.gpg || catch

step 4 "Adding repository to '/etc/apt/sources.list.d/ppr.list'"
echo "deb [signed-by=/usr/share/keyrings/ppr-keyring.gpg arch=${joined_archs%,}] https://ppr.pacstall.dev/pacstall/ pacstall ${chosen_components[*]}" | sudo tee /etc/apt/sources.list.d/ppr.list > /dev/null || catch

echo "Done! Make sure to run 'sudo apt update'!"
