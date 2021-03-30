#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039
#
# This file must be identical in: configs/ci-work/, app/ci-work/, restapi/ci-work/, summerwood/ci-work/, sync-server/ci-work/, viewer-html/ci-work/
#
# Usage: This script marks the given docker imagetag as deployed to production
# 0) bash ci-work/99-mark-as-prod.sh [--COMPONENTS_TO_UPDATE=[i|v|a|s|w] ] [--XUVER_API_IMAGETAG=latest] [--XUVER_VIEWER_IMAGETAG=latest] [--XUVER_APP_IMAGETAG=latest] [--XUVER_SYNC_IMAGETAG=latest] [--XUVER_SUMMERWOOD_IMAGETAG=latest] [--SILENT]

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

echo -e "\n${BLINK}!!! Make sure you ran${DEFAULT} \"docker login ${CI_REGISTRY}\"\n";

echo ; echo "--- Retagging docker images"
retag-for-prod() {
  imagename="${1}";     imagetag="${2}"
  docker pull "${imagename}:${imagetag}"
  docker tag "${imagename}:${imagetag}" "${imagename}:latest-prod-${imagetag}"
  docker push "${imagename}:latest-prod-${imagetag}"
}

get_var_value --var_name=COMPONENTS_TO_UPDATE --val_regex="[ivaswd]" --var_value_hint="i=API,v=VIEWER,a=APP,s=SYNC,w=SUMMERWOOD,d=DOWNLOADS" --var_default_value="ivaswd" --skip_env_file "${arguments_main[*]}"

if [[ $COMPONENTS_TO_UPDATE = *"i"* ]]; then
  get_var_value --var_name=XUVER_API_IMAGETAG        --val_regex=".*" --var_value_hint="new_imagetag" --var_default_value="${XUVER_API_IMAGETAG:-latest}" --skip_env_file "${arguments_main[*]}";
  retag-for-prod "${IMAGES_BASE_PATH}restapi" "${XUVER_API_IMAGETAG}"
fi
if [[ $COMPONENTS_TO_UPDATE = *"v"* ]]; then
  get_var_value --var_name=XUVER_VIEWER_IMAGETAG     --val_regex=".*" --var_value_hint="new_imagetag" --var_default_value="${XUVER_VIEWER_IMAGETAG:-latest}" --skip_env_file "${arguments_main[*]}";
  retag-for-prod "${IMAGES_BASE_PATH}viewer-html" "${XUVER_VIEWER_IMAGETAG}"
fi
if [[ $COMPONENTS_TO_UPDATE = *"a"* ]]; then
  get_var_value --var_name=XUVER_APP_IMAGETAG        --val_regex=".*" --var_value_hint="new_imagetag" --var_default_value="${XUVER_APP_IMAGETAG:-latest}" --skip_env_file "${arguments_main[*]}";
  retag-for-prod "${IMAGES_BASE_PATH}app" "${XUVER_APP_IMAGETAG}"
fi
if [[ $COMPONENTS_TO_UPDATE = *"s"* ]]; then
  get_var_value --var_name=XUVER_SYNC_IMAGETAG       --val_regex=".*" --var_value_hint="new_imagetag" --var_default_value="${XUVER_SYNC_IMAGETAG:-latest}" --skip_env_file "${arguments_main[*]}";
  retag-for-prod "${IMAGES_BASE_PATH}sync-server" "${XUVER_SYNC_IMAGETAG}"
fi
if [[ $COMPONENTS_TO_UPDATE = *"w"* ]]; then
  get_var_value --var_name=XUVER_SUMMERWOOD_IMAGETAG --val_regex=".*" --var_value_hint="new_imagetag" --var_default_value="${XUVER_SUMMERWOOD_IMAGETAG:-latest}" --skip_env_file "${arguments_main[*]}";
  retag-for-prod "${IMAGES_BASE_PATH}summerwood" "${XUVER_SUMMERWOOD_IMAGETAG}"
fi
if [[ $COMPONENTS_TO_UPDATE = *"d"* ]]; then
  get_var_value --var_name=XUVER_DOWNLOADS_IMAGETAG --val_regex=".*" --var_value_hint="new_imagetag" --var_default_value="${XUVER_DOWNLOADS_IMAGETAG:-latest}" --skip_env_file "${arguments_main[*]}";
  retag-for-prod "${IMAGES_BASE_PATH}downloads" "${XUVER_DOWNLOADS_IMAGETAG}"
fi

cmd="cd \"${startDir}\""; echo ; echo " >>> $cmd"; eval "$cmd"
echo ; echo "=== End (duration $(seconds_to_time $SECONDS)) - $(date) - ${HOSTNAME}: ${scriptFullName} ${arguments_main[*]}"
