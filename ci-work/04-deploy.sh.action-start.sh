#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039
#
# This file must be identical in: configs/ci-work/, app/ci-work/, restapi/ci-work/, summerwood/ci-work/, sync-server/ci-work/, viewer-html/ci-work/
#

trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR
echo_and_exit1() { echo ; echo -e "${1} (${2}, ${BASH_SOURCE[0]})"; echo ; exit 1; }

echo ; echo "-- Starting scripts  ${USER}@${HOSTNAME}:/xuver/xuver.deployment/"
arguments_main=( "$@" )

cmd="bash /xuver/xuver.deployment/deployup.sh ${arguments_main[*]}"; echo ; echo " >>> $cmd"; eval "$cmd";

echo ; echo "-- End"
