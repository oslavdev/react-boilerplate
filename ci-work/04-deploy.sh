#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039
#
# This file must be identical in: configs/ci-work/, app/ci-work/, restapi/ci-work/, summerwood/ci-work/, sync-server/ci-work/, viewer-html/ci-work/
#
# Usage: 
# 0) bash ci-work/04-deploy.sh [--TARGET=.] [--ACTION=[t|i|u|s] ] [--COMPONENTS_TO_UPDATE=[i|v|a|s|w] ] [--XUVER_API_IMAGETAG=latest] [--XUVER_VIEWER_IMAGETAG=latest] [--XUVER_APP_IMAGETAG=latest] [--XUVER_SYNC_IMAGETAG=latest] [--XUVER_SUMMERWOOD_IMAGETAG=latest] [--COMPONENTS=[p|i|v|a|s|w] ] [--SILENT]
# 1) Stop all XUVER components
# $ bash ci-work/04-deploy.sh --TARGET=. --ACTION=t
# 2) Start all XUVER components
# $ bash ci-work/04-deploy.sh --TARGET=. --ACTION=s  --COMPONENTS=pivasw --SILENT
# 3) Get the latest deployment scripts and start all XUVER components
# $ bash ci-work/04-deploy.sh --TARGET=. --ACTION=is --COMPONENTS=pivasw --SILENT
# 4) Get the latest deployment scripts, update API and start all XUVER components
# $ bash ci-work/04-deploy.sh --TARGET=. --ACTION=ius --COMPONENTS_TO_UPDATE=i --XUVER_API_IMAGETAG=latest --COMPONENTS=pivasw --SILENT
# 5) Get the latest deployment scripts, update all XUVER components and start all XUVER components
# $ bash ci-work/04-deploy.sh --TARGET=. --ACTION=tius --COMPONENTS_TO_UPDATE=ivasw --XUVER_API_IMAGETAG=latest --XUVER_VIEWER_IMAGETAG=latest --XUVER_APP_IMAGETAG=latest --XUVER_SYNC_IMAGETAG=latest --XUVER_SUMMERWOOD_IMAGETAG=latest --COMPONENTS=pivasw --VOLUMES --RMI --SILENT

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

echo -e "\n  ${BLINK}!!! === ATENTION === !!!${DEFAULT}
  ${BLINK}!!!${DEFAULT}  The target system must be ready for deployment:
  ${BLINK}!!!${DEFAULT}  - File /xuver/hostspecific with required values (like HOST_IP, REGISTRY_PREFIX, REGISTRY_USER, REGISTRY_PSW, IMAGES_BASE_PATH, ...)
  ${BLINK}!!!${DEFAULT}  - File /etc/hosts and /xuver/hostspecific with permissions of the current user
  ${BLINK}!!!${DEFAULT}  - SSH access - in case of remote deployment
  ${BLINK}!!! !!! !!! !!! !!! !!!${DEFAULT}
";

get_var_value --var_name=TARGET --val_regex=".*" --var_value_hint="deployment_target_address(dot_for_localhost)_in_format_user@address" --var_default_value="." "${arguments_main[*]}"
if [[ "${TARGET}" == "." ]]; then cmd_prefix=""; else cmd_prefix="ssh -oStrictHostKeyChecking=no ${TARGET}"; fi

get_var_value --var_name=ACTION --val_regex="t|i|u|s" --var_value_hint="t=stop,i=install_latest_deployment_scripts,u=update,s=start" --var_default_value="itsu" "${arguments_main[*]}"

if [[ "${ACTION}" == *"t"* ]]; then
  full_cmd="${cmd_prefix} bash -s -- < ${scriptFullPath}/${scriptBaseName}.action-stop.sh ${arguments_main[*]}"; echo ; echo " >>> $full_cmd"; eval "$full_cmd"
fi

if [[ "${ACTION}" == *"i"* ]]; then
  full_cmd="${cmd_prefix} bash -s -- < ${scriptFullPath}/${scriptBaseName}.action-install.sh"; echo ; echo " >>> $full_cmd"; eval "$full_cmd"
fi

if [[ "${ACTION}" == *"u"* ]]; then
  echo ; echo "--- Updating XUVER components on ${TARGET}:/xuver/xuver.deployment/"
  get_var_value --var_name=COMPONENTS_TO_UPDATE --val_regex="[ivaswd]" --var_value_hint="i=API,v=VIEWER,a=APP,s=SYNC,w=SUMMERWOOD,d=DOWNLOADS" --var_default_value="ivaswd" --skip_env_file "${arguments_main[*]}"
  imagetags="";
  if [[ $COMPONENTS_TO_UPDATE = *"i"* ]]; then
    get_var_value --var_name=XUVER_API_IMAGETAG        --val_regex=".*" --var_value_hint="new_imagetag" --var_default_value="${XUVER_API_IMAGETAG:-latest}" --skip_env_file "${arguments_main[*]}";
    imagetags="${imagetags} --XUVER_API_IMAGETAG=${XUVER_API_IMAGETAG}"
  fi
  if [[ $COMPONENTS_TO_UPDATE = *"v"* ]]; then
    get_var_value --var_name=XUVER_VIEWER_IMAGETAG     --val_regex=".*" --var_value_hint="new_imagetag" --var_default_value="${XUVER_VIEWER_IMAGETAG:-latest}" --skip_env_file "${arguments_main[*]}";
    imagetags="${imagetags} --XUVER_VIEWER_IMAGETAG=${XUVER_VIEWER_IMAGETAG}"
  fi
  if [[ $COMPONENTS_TO_UPDATE = *"a"* ]]; then
    get_var_value --var_name=XUVER_APP_IMAGETAG        --val_regex=".*" --var_value_hint="new_imagetag" --var_default_value="${XUVER_APP_IMAGETAG:-latest}" --skip_env_file "${arguments_main[*]}";
    imagetags="${imagetags} --XUVER_APP_IMAGETAG=${XUVER_APP_IMAGETAG}"
  fi
  if [[ $COMPONENTS_TO_UPDATE = *"s"* ]]; then
    get_var_value --var_name=XUVER_SYNC_IMAGETAG       --val_regex=".*" --var_value_hint="new_imagetag" --var_default_value="${XUVER_SYNC_IMAGETAG:-latest}" --skip_env_file "${arguments_main[*]}";
    imagetags="${imagetags} --XUVER_SYNC_IMAGETAG=${XUVER_SYNC_IMAGETAG}"
  fi
  if [[ $COMPONENTS_TO_UPDATE = *"w"* ]]; then
    get_var_value --var_name=XUVER_SUMMERWOOD_IMAGETAG --val_regex=".*" --var_value_hint="new_imagetag" --var_default_value="${XUVER_SUMMERWOOD_IMAGETAG:-latest}" --skip_env_file "${arguments_main[*]}";
    imagetags="${imagetags} --XUVER_SUMMERWOOD_IMAGETAG=${XUVER_SUMMERWOOD_IMAGETAG}"
  fi
  if [[ $COMPONENTS_TO_UPDATE = *"d"* ]]; then
    get_var_value --var_name=XUVER_DOWNLOADS_IMAGETAG --val_regex=".*" --var_value_hint="new_imagetag" --var_default_value="${XUVER_DOWNLOADS_IMAGETAG:-latest}" --skip_env_file "${arguments_main[*]}";
    imagetags="${imagetags} --XUVER_DOWNLOADS_IMAGETAG=${XUVER_DOWNLOADS_IMAGETAG}"
  fi

  full_cmd="${cmd_prefix} bash -s -- < ${scriptFullPath}/${scriptBaseName}.action-update.sh ${arguments_main[*]} ${imagetags} --ACTION=s --COMPONENTS_TO_UPDATE=${COMPONENTS_TO_UPDATE} --COMPONENTS=${COMPONENTS} --SILENT"; echo ; echo " >>> $full_cmd"; eval "$full_cmd"
fi

if [[ "${ACTION}" == *"s"* ]]; then
  echo ; echo "--- Starting XUVER on ${TARGET}:/xuver/xuver.deployment/"
  get_var_value --var_name=COMPONENTS --val_regex="[pivaswd]" --var_value_hint="p=POSTGRES,i=API,v=VIEWER,a=APP,s=SYNC,w=SUMMERWOOD,d=DOWNLOADS" --var_default_value="pivaswd" --skip_env_file "${arguments_main[*]}"
  full_cmd="${cmd_prefix} bash -s -- < ${scriptFullPath}/${scriptBaseName}.action-start.sh ${arguments_main[*]} --COMPONENTS=${COMPONENTS} --SILENT"; echo ; echo " >>> $full_cmd"; eval "$full_cmd"
fi

cmd="cd \"${startDir}\""; echo ; echo " >>> $cmd"; eval "$cmd"
echo ; echo "=== End (duration $(seconds_to_time $SECONDS)) - $(date) - ${HOSTNAME}: ${scriptFullName} ${arguments_main[*]}"
