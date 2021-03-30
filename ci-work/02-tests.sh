#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039
#
# This file must be identical in: configs/ci-work/, app/ci-work/, restapi/ci-work/, summerwood/ci-work/, sync-server/ci-work/, viewer-html/ci-work/
#
# Usage: $ bash ci-work/02-tests.sh
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

cmd="cd ${CI_PROJECT_DIR}"; echo ; echo " >>> $cmd"; eval "$cmd"

echo -e "\n${BLINK}!!! Make sure you ran${DEFAULT} \"docker login ${CI_REGISTRY}\"\n";

if [[ -f ${CI_PROJECT_DIR}/.env ]]; then ci_deploy_down; fi

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
#XUVER_API_DB_HOST= - this must not be declared, otherwise the test Config.EnvironmentVariableDbHost fails
FLYWAY_URL=jdbc:postgresql://postgres/xuver
POSTGRES_DB=xuver_test
POSTGRES_USER=xuver
POSTGRES_PASSWORD=xuver
ENV
cmd="cat ${CI_PROJECT_DIR}/.env"; echo ; echo " >>> $cmd"; eval "$cmd";

cmd="docker-compose --project-directory ${CI_PROJECT_DIR} --file ${scriptFullPath}/all-docker-compose.yaml up -d postgres"; echo ; echo " >>> $cmd"; eval "$cmd";
container=$(docker inspect --format "{{.Name}}" "$(docker-compose --project-directory "${CI_PROJECT_DIR}" --file "${CI_PROJECT_DIR}"/ci-work/all-docker-compose.yaml ps -q postgres)")
check_docker_container_health "${container}"
cmd="docker-compose --project-directory ${CI_PROJECT_DIR} --file ${scriptFullPath}/all-docker-compose.yaml up -d tester";   echo ; echo " >>> $cmd"; eval "$cmd";
container=$(docker inspect --format "{{.Name}}" "$(docker-compose --project-directory "${CI_PROJECT_DIR}" --file "${CI_PROJECT_DIR}"/ci-work/all-docker-compose.yaml ps -q tester)")
check_docker_container_health "${container}"

echo -e "\n--- Launching the tests"
cmd_prefix="docker-compose --project-directory ${CI_PROJECT_DIR} -f ${scriptFullPath}/all-docker-compose.yaml exec -T tester "
cmd="${cmd_prefix} bash ./ci-work/${scriptBaseName}.in-tester.sh"; echo ; echo " >>> $cmd"; eval "$cmd"

ci_deploy_down

cmd="cd \"${startDir}\""; echo ; echo " >>> $cmd"; eval "$cmd"
echo -e "\n=== End (duration $(seconds_to_time $SECONDS)) - $(date) - ${HOSTNAME}: ${scriptFullName} ${arguments_main[*]}\n"
