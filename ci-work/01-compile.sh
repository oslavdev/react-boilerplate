#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039
#
# This file must be identical in: configs/ci-work/, app/ci-work/, restapi/ci-work/, summerwood/ci-work/, sync-server/ci-work/, viewer-html/ci-work/
#
# Usage: $ bash ci-work/01-compile.sh [--CLEAN_BUILD_DIR=n|y]
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

if [[ -z $CURRENT_COMPONENT ]]; then
  get_var_value --var_name=CURRENT_COMPONENT --val_regex="i|v|a|s|w|d" --var_value_hint="i=API,v=VIEWER,a=APP,s=SYNC,w=SUMMERWOOD,d=DOWNLOADS" --var_default_value="" --skip_env_file "${arguments_main[*]}"
else echo "./ci-work/projectspecific |-> CURRENT_COMPONENT=${CURRENT_COMPONENT}"
fi

BUILD_DIR_DEFAULT=""
if [[ ${CURRENT_COMPONENT} == *"a"* ]]; then BUILD_DIR_DEFAULT="dist";
  elif [[ ${CURRENT_COMPONENT} == *"w"* ]]; then BUILD_DIR_DEFAULT="dist";
  elif [[ ${CURRENT_COMPONENT} == *"v"* ]]; then BUILD_DIR_DEFAULT="dist";
  elif [[ ${CURRENT_COMPONENT} == *"i"* ]]; then BUILD_DIR_DEFAULT="build";
  elif [[ ${CURRENT_COMPONENT} == *"s"* ]]; then BUILD_DIR_DEFAULT="out";
  elif [[ ${CURRENT_COMPONENT} == *"d"* ]]; then BUILD_DIR_DEFAULT="_nothing_";
fi
if [[ -z $BUILD_DIR ]]; then
  get_var_value --var_name=BUILD_DIR --val_regex=".*" --var_value_hint="output_dir(relative_to_PWD)" --var_default_value="${BUILD_DIR_DEFAULT}" --skip_env_file "${arguments_main[*]}"
else echo "./ci-work/projectspecific |-> BUILD_DIR=${BUILD_DIR}"
fi

cmd="cd ${CI_PROJECT_DIR}"; echo ; echo " >>> $cmd"; eval "$cmd"

echo -e "\n${BLINK}!!! Make sure you ran${DEFAULT} \"docker login ${CI_REGISTRY}\"\n";

get_var_value --var_name=CLEAN_BUILD_DIR --val_regex="y|n" --var_value_hint="clean_the_folder_${BUILD_DIR}?" --var_default_value="n" --skip_env_file "${arguments_main[*]}"
if [[ "${CLEAN_BUILD_DIR}" == "y" || "${CLEAN_BUILD_DIR}" == "Y" ]]; then
  ci_deploy_down
  cmd="rm -rfd \
    ${CI_PROJECT_DIR}/${BUILD_DIR} \
    ${CI_PROJECT_DIR}/ci-artifacts/ \
    ${CI_PROJECT_DIR}/node_modules/ \
    ${CI_PROJECT_DIR}/.ccache/ \
    ${CI_PROJECT_DIR}/junit.xml \
    ${CI_PROJECT_DIR}/.env \
    ${CI_PROJECT_DIR}/xversion.env \
    ${CI_PROJECT_DIR}/xversion.html \
    && mkdir -pv ${CI_PROJECT_DIR}/${BUILD_DIR} ${CI_PROJECT_DIR}/ci-artifacts/"; echo ; echo " >>> $cmd"; eval "$cmd"
fi

echo -e "\n--- Prepare the field"
cat >"${CI_PROJECT_DIR}/.env" <<ENV
COMPOSE_PROJECT_NAME=${CI_PROJECT_NAME}
USER_ID=$(id -u)
GROUP_ID=$(id -g)
HOME_DIR=${HOME}
CI_PROJECT_DIR=${CI_PROJECT_DIR}
BUILD_DIR=${BUILD_DIR}
CI_PROJECT_NAME=${CI_PROJECT_NAME}
IMAGES_BASE_PATH=${IMAGES_BASE_PATH}
XPROJECT_COMPILER=${XPROJECT_COMPILER}
XPROJECT_RUNNER=${XPROJECT_RUNNER}
POSTGRES_DATA_DIR=/xuver/postgres_data/
ENV
cmd="cat ${CI_PROJECT_DIR}/.env"; echo ; echo " >>> $cmd"; eval "$cmd";

IMAGETAG="${IMAGETAG_PREFIX}-$(date +%Y%m%d%H%M)"; echo " -> IMAGETAG=${IMAGETAG}"

cmd="docker-compose --project-directory ${CI_PROJECT_DIR} --file ${CI_PROJECT_DIR}/ci-work/all-docker-compose.yaml up -d compiler"; echo ; echo " >>> $cmd"; eval "$cmd";
container=$(docker inspect --format "{{.Name}}" "$(docker-compose --project-directory "${CI_PROJECT_DIR}" --file "${CI_PROJECT_DIR}"/ci-work/all-docker-compose.yaml ps -q compiler)")
check_docker_container_health "${container}"

cmd_prefix="docker-compose --project-directory ${CI_PROJECT_DIR} -f ${CI_PROJECT_DIR}/ci-work/all-docker-compose.yaml exec -T -u root compiler "
cmd="${cmd_prefix} mkdir -pv ${HOME}/.npm/ ${HOME}/node_modules/ ${HOME}/.config/"; echo ; echo " >>> $cmd"; eval "$cmd"
cmd="${cmd_prefix} chmod 777 ${HOME}/.npm/ ${HOME}/node_modules/ ${HOME}/.config/ -R"; echo ; echo " >>> $cmd"; eval "$cmd"

if   [[ ${CURRENT_COMPONENT} == *"a"* ]]; then IMAGETAG_VAR="XUVER_APP_IMAGETAG";
elif [[ ${CURRENT_COMPONENT} == *"i"* ]]; then IMAGETAG_VAR="XUVER_API_IMAGETAG";
elif [[ ${CURRENT_COMPONENT} == *"w"* ]]; then IMAGETAG_VAR="XUVER_SUMMERWOOD_IMAGETAG";
elif [[ ${CURRENT_COMPONENT} == *"s"* ]]; then IMAGETAG_VAR="XUVER_SYNC_IMAGETAG";
elif [[ ${CURRENT_COMPONENT} == *"v"* ]]; then IMAGETAG_VAR="XUVER_VIEWER_IMAGETAG";
elif [[ ${CURRENT_COMPONENT} == *"d"* ]]; then IMAGETAG_VAR="XUVER_DOWNLOADS_IMAGETAG";
fi
upsert_var_into_file --var_name="IMAGETAG" --var_value="${IMAGETAG}" --var_file="${BUILD_INFO_FILE}"
upsert_var_into_file --var_name="${IMAGETAG_VAR}" --var_value="${IMAGETAG}" --var_file="${BUILD_INFO_FILE}"

cmd="cat ${BUILD_INFO_FILE}"; echo ; echo " >>> $cmd"; eval "$cmd"
cmd="echo \"${CI_PROJECT_NAMESPACE} ${CI_PROJECT_NAME} ${IMAGETAG}\" > ${CI_PROJECT_DIR}/xversion.html"; echo ; echo " >>> $cmd"; eval "$cmd"
cmd="cat ${CI_PROJECT_DIR}/xversion.html"; echo ; echo " >>> $cmd"; eval "$cmd"

echo -e "\n--- Compiling"
cmd_prefix="docker-compose --project-directory ${CI_PROJECT_DIR} -f ${CI_PROJECT_DIR}/ci-work/all-docker-compose.yaml exec -T compiler "
cmd="${cmd_prefix} bash /${CI_PROJECT_NAME}/ci-work/01-compile.sh.in-compiler.sh"; echo ; echo " >>> $cmd"; eval "$cmd"

echo -e "\n--- Finished. Find the output in the folder ${CI_PROJECT_DIR}/${BUILD_DIR}\n"

ci_deploy_down

cmd="cd \"${startDir}\""; echo ; echo " >>> $cmd"; eval "$cmd"
echo -e "\n=== End (duration $(seconds_to_time $SECONDS)) - $(date) - ${HOSTNAME}: ${scriptFullName} ${arguments_main[*]}\n"
