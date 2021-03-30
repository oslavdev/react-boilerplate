#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039
#
# This file must be identical in: configs/ci-work/, app/ci-work/, restapi/ci-work/, summerwood/ci-work/, sync-server/ci-work/, viewer-html/ci-work/
#

trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR
echo_and_exit1() { echo ; echo -e "${1} (${2}, ${BASH_SOURCE[0]})"; echo ; exit 1; }

echo ; echo "-- Installing scripts  ${USER}@${HOSTNAME}:/xuver/xuver.deployment/"

cmd="source /xuver/hostspecific"; echo ; echo " >>> $cmd"; eval "$cmd";
cmd="docker login ${REGISTRY_PREFIX} -u ${REGISTRY_USER} --password-stdin"; echo ; echo " >>> $cmd"; eval "echo ${REGISTRY_PSW} | base64 -d | $cmd";

cmd="docker pull ${IMAGES_BASE_PATH}xdeploy:latest"; echo ; echo " >>> $cmd"; eval "$cmd";
cmd="docker run -u $(id -u):$(id -g) --rm -i -v /xuver/:/host/ ${IMAGES_BASE_PATH}xdeploy:latest cp -R /xuver.deployment /host/"; echo ; echo " >>> $cmd"; eval "$cmd";

echo ; echo "-- End"
