#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039

startDir="$PWD";
scriptFullPath="$(dirname "$(readlink -f "$0")")";
scriptBaseName="$(basename "$0")"
scriptFullName="${scriptFullPath}/${scriptBaseName}"
trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR
echo_and_exit1() { echo ; echo -e "${1} (${2}, ${scriptFullName} / ${BASH_SOURCE[0]})"; echo ; exit 1; }

echo ; echo "=== Begin - $(date) - ${HOSTNAME}: ${scriptFullName}"

cmd="WORKSPACE=$(readlink -f "${scriptFullPath}"/..)"; echo ; echo " >>> $cmd"; eval "$cmd"
cmd="mkdir -pv ${WORKSPACE}/${BUILD_DIR}"; echo ; echo " >>> $cmd"; eval "$cmd"

cmd="npm ci"; echo ; echo " >>> $cmd"; eval "$cmd"
cmd="npm run build"; echo ; echo " >>> $cmd"; eval "$cmd"

echo -e "\n--- Finished. Find the output in the folder ${WORKSPACE}/${BUILD_DIR}/\n"

cmd="cd \"${startDir}\""; echo ; echo " >>> $cmd"; eval "$cmd"
echo ; echo "=== End - $(date) - ${HOSTNAME}: ${scriptFullName}"
