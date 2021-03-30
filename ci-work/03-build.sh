#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039
#
# This file must be identical in: configs/ci-work/, app/ci-work/, restapi/ci-work/, summerwood/ci-work/, sync-server/ci-work/, viewer-html/ci-work/
#
# Usage: $ bash ci-work/03-build.sh [--ACTION=b|p|bp]
#

startDir="$PWD"
scriptFullPath="$(dirname "$(readlink -f "$0")")";
scriptBaseName="$(basename "$0")"
scriptFullName="${scriptFullPath}/${scriptBaseName}"
cmd="cd \"${scriptFullPath}\""; echo ; echo " >>> $cmd"; eval "$cmd"
cmd="source .deploy.tools.sh"; echo ; echo " >>> $cmd"; eval "$cmd"

trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR

if [[ "$1"_ == "--help"_ ]]; then "${scriptBaseName}_help"; exit 0; fi

arguments_main=( "$@" )
echo ; echo "=== Begin - $(date) - ${HOSTNAME}: ${scriptFullName} ${arguments_main[*]}"
cmd="cd \"${scriptFullPath}/..\""; echo ; echo " >>> $cmd"; eval "$cmd"

if [[ -z $CURRENT_COMPONENT ]]; then
  get_var_value --var_name=CURRENT_COMPONENT --val_regex="i|v|a|s|w|d" --var_value_hint="i=API,v=VIEWER,a=APP,s=SYNC,w=SUMMERWOOD,d=DOWNLOADS" --var_default_value="" --skip_env_file "${arguments_main[*]}"
else echo "./ci-work/projectspecific |-> CURRENT_COMPONENT=${CURRENT_COMPONENT}"
fi

IMAGETAG_VAR=""
if   [[ ${CURRENT_COMPONENT} == *"a"* ]]; then IMAGETAG_VAR="XUVER_APP_IMAGETAG";
elif [[ ${CURRENT_COMPONENT} == *"i"* ]]; then IMAGETAG_VAR="XUVER_API_IMAGETAG";
elif [[ ${CURRENT_COMPONENT} == *"w"* ]]; then IMAGETAG_VAR="XUVER_SUMMERWOOD_IMAGETAG";
elif [[ ${CURRENT_COMPONENT} == *"s"* ]]; then IMAGETAG_VAR="XUVER_SYNC_IMAGETAG";
elif [[ ${CURRENT_COMPONENT} == *"v"* ]]; then IMAGETAG_VAR="XUVER_VIEWER_IMAGETAG";
elif [[ ${CURRENT_COMPONENT} == *"d"* ]]; then IMAGETAG_VAR="XUVER_DOWNLOADS_IMAGETAG";
fi
cmd="IMAGETAG=${!IMAGETAG_VAR}"; echo ; echo " >>> $cmd"; eval "$cmd"

if [[ -z $IMAGETAG ]]; then echo_and_exit1 "ERROR! IMAGETAG is empty." ${LINENO}; fi

echo -e "\n${BLINK}!!! Make sure you ran${DEFAULT} \"docker login ${CI_REGISTRY}\"\n";

get_var_value --var_name=ACTION --val_regex="b|p|bp" --var_value_hint="b=build,p=push" --var_default_value="b" "${arguments_main[*]}"

if [[ "${ACTION}" == *"b"* ]]; then
  echo ; echo "--- Building (or creating) the image"
  cmd="docker rmi -f ${IMAGES_BASE_PATH}${CI_PROJECT_NAME}:${IMAGETAG} ${IMAGES_BASE_PATH}${CI_PROJECT_NAME}:latest || true"; echo ; echo " >>> $cmd"; eval "$cmd"
  cmd="docker build ${CI_PROJECT_DIR}/ -f ./docker/Dockerfile -t ${IMAGES_BASE_PATH}${CI_PROJECT_NAME}:${IMAGETAG} -t ${IMAGES_BASE_PATH}${CI_PROJECT_NAME}:latest --build-arg XPROJECT_RUNNER=${XPROJECT_RUNNER}"; echo ; echo " >>> $cmd"; eval "$cmd";
fi
if [[ "${ACTION}" == *"p"* ]]; then
  echo ; echo "--- Pushing the image"
  cmd="docker push ${IMAGES_BASE_PATH}${CI_PROJECT_NAME}:${IMAGETAG}"; echo ; echo " >>> $cmd"; eval "$cmd"
  cmd="docker push ${IMAGES_BASE_PATH}${CI_PROJECT_NAME}:latest"; echo ; echo " >>> $cmd"; eval "$cmd"
fi

echo -e ".\n. PROCESSED ${IMAGES_BASE_PATH}${CI_PROJECT_NAME}:${IMAGETAG}\n.";

cmd="cd \"${startDir}\""; echo ; echo " >>> $cmd"; eval "$cmd"
echo ; echo "=== End (duration $(seconds_to_time $SECONDS)) - $(date) - ${HOSTNAME}: ${scriptFullName} ${arguments_main[*]}"
