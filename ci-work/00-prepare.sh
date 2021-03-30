#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039
#
# This file must be identical in: configs/ci-work/, app/ci-work/, restapi/ci-work/, summerwood/ci-work/, sync-server/ci-work/, viewer-html/ci-work/
#

startDir="$PWD"
scriptFullPath="$(dirname "$(readlink -f "$0")")";
scriptBaseName="$(basename "$0")"
scriptFullName="${scriptFullPath}/${scriptBaseName}"
cmd="cd ${scriptFullPath}"; echo ; echo " >>> $cmd"; eval "$cmd"
cmd="source .deploy.tools.sh"; echo ; echo " >>> $cmd"; eval "$cmd"

trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR

if [[ "$1"_ == "--help"_ ]]; then "${scriptBaseName}_help"; exit 0; fi

arguments_main=( "$@" )
echo ; echo "=== Begin - $(date) - ${HOSTNAME}: ${scriptFullName} ${arguments_main[*]}"

echo -e "\n${BLINK}!!! Make sure you ran${DEFAULT} \"docker login ${CI_REGISTRY}\"\n";

get_var_value --var_name=ACTION --val_regex="b|f|bp|fp" --var_value_hint="b=build,f=force_rebuild,p=push" --var_default_value="b" "${arguments_main[*]}"

diffs=""
if [[ "${ACTION}" == *"b"* ]]; then
  echo ; echo "--- Checking if it is required to build ${XPROJECT_COMPILER}:latest"
  cmd="docker run --rm ${XPROJECT_COMPILER}:latest cat /Dockerfile-compiler > /tmp/Dockerfile-compiler"; echo ; echo " >>> $cmd"; eval "$cmd" || true
  cmd="diffs=\"$(diff -abBNqw "${CI_PROJECT_DIR}"/ci-work/Dockerfile-compiler /tmp/Dockerfile-compiler || true)\""; echo ; echo " >>> $cmd"; eval "$cmd"
  if [[ -z "$diffs" ]]; then echo "No changes to be added. The rebuild is not necesary."; fi
fi
if [[ "${ACTION}" == *"f"* || "${ACTION}" == *"b"* && -n "$diffs" ]]; then
  echo ; echo "--- Building (or creating) the image ${XPROJECT_COMPILER}"
  cmd="docker rmi -f ${XPROJECT_COMPILER}:${IMAGETAG} ${XPROJECT_COMPILER}:latest || true"; echo ; echo " >>> $cmd"; eval "$cmd"
  cmd="docker build ${CI_PROJECT_DIR}/ -f ${CI_PROJECT_DIR}/ci-work/Dockerfile-compiler -t ${XPROJECT_COMPILER}:${IMAGETAG} -t ${XPROJECT_COMPILER}:latest --build-arg IMAGES_BASE_PATH=${IMAGES_BASE_PATH}"; echo ; echo " >>> $cmd"; eval "$cmd"
fi
if [[ "${ACTION}" == "fp" || "${ACTION}" == "bp" && -n "$diffs" ]]; then
  echo ; echo "--- Pushing the image ${XPROJECT_COMPILER}"
  cmd="docker push ${XPROJECT_COMPILER}:${IMAGETAG}"; echo ; echo " >>> $cmd"; eval "$cmd"
  cmd="docker push ${XPROJECT_COMPILER}:latest"; echo ; echo " >>> $cmd"; eval "$cmd"
fi

if [[ "${ACTION}" == *"b"* ]]; then
  echo ; echo "--- Checking if it is required to build ${XPROJECT_RUNNER}:latest"
  cmd="docker run --rm ${XPROJECT_RUNNER}:latest cat /Dockerfile-runner > /tmp/Dockerfile-runner"; echo ; echo " >>> $cmd"; eval "$cmd" || true
  cmd="diffs=\"$(diff -abBNqw "${CI_PROJECT_DIR}"/ci-work/Dockerfile-runner /tmp/Dockerfile-runner || true)\""; echo ; echo " >>> $cmd"; eval "$cmd"
  if [[ -z "$diffs" ]]; then echo "No changes to be added. The rebuild is not necesary."; fi
fi
if [[ "${ACTION}" == *"f"* || "${ACTION}" == *"b"* && -n "$diffs" ]]; then
  echo ; echo "--- Building (or creating) the image ${XPROJECT_RUNNER}"
  cmd="docker rmi -f ${XPROJECT_RUNNER}:${IMAGETAG} ${XPROJECT_RUNNER}:latest || true"; echo ; echo " >>> $cmd"; eval "$cmd"
  cmd="docker build ${CI_PROJECT_DIR}/ -f ${CI_PROJECT_DIR}/ci-work/Dockerfile-runner -t ${XPROJECT_RUNNER}:${IMAGETAG} -t ${XPROJECT_RUNNER}:latest --build-arg IMAGES_BASE_PATH=${IMAGES_BASE_PATH}"; echo ; echo " >>> $cmd"; eval "$cmd"
fi
if [[ "${ACTION}" == "fp" || "${ACTION}" == "bp" && -n "$diffs" ]]; then
  echo ; echo "--- Pushing the image ${XPROJECT_RUNNER}"
  cmd="docker push ${XPROJECT_RUNNER}:${IMAGETAG}"; echo ; echo " >>> $cmd"; eval "$cmd"
  cmd="docker push ${XPROJECT_RUNNER}:latest"; echo ; echo " >>> $cmd"; eval "$cmd"
fi

cmd="cd \"${startDir}\""; echo ; echo " >>> $cmd"; eval "$cmd"
echo ; echo "=== End (duration $(seconds_to_time $SECONDS)) - $(date) - ${HOSTNAME}: ${scriptFullName} ${arguments_main[*]}"
