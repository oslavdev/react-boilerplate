#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039
#
# This file must be identical in: configs/ci-work/, app/ci-work/, restapi/ci-work/, summerwood/ci-work/, sync-server/ci-work/, viewer-html/ci-work/
#
# Usage: $ bash ci-work/02-scan-code.sh
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

echo ; echo "--- Scanning for security vulnerabilities using OWASP ZAP tool"
echo ; echo "   !!! Make sure you are allowed to do that !!!"; echo ;

if [[ ${CURRENT_COMPONENT} == *"a"* ]]; then PREFIX_ADDRESS="app";
  elif [[ ${CURRENT_COMPONENT} == *"w"* ]]; then PREFIX_ADDRESS="summerwood";
  elif [[ ${CURRENT_COMPONENT} == *"v"* ]]; then PREFIX_ADDRESS="viewer";
  elif [[ ${CURRENT_COMPONENT} == *"i"* ]]; then PREFIX_ADDRESS="api";
  elif [[ ${CURRENT_COMPONENT} == *"s"* ]]; then PREFIX_ADDRESS="sync";
  elif [[ ${CURRENT_COMPONENT} == *"d"* ]]; then PREFIX_ADDRESS="downloads";
fi

DEFAULT_VALUE="https://${PREFIX_ADDRESS}.${DOMAIN}"
if [[ -n ${TARGET_URL} && ${TARGET_URL} == "__default__" ]]; then TARGET_URL="${DEFAULT_VALUE}";
else
  get_var_value --var_name=TARGET_URL --val_regex=".*" --var_value_hint="Target_URL_to_scan" --var_default_value="${DEFAULT_VALUE}" "${arguments_main[*]}"
fi

get_var_value --var_name=SCAN_TYPE --val_regex="baseline|full-scan" --var_value_hint="baseline_scan_or_full-scan" --var_default_value="baseline" "${arguments_main[*]}"

cmd="mkdir -pv ${CI_PROJECT_DIR}/ci-artifacts/"; echo ; echo " >>> $cmd"; eval "$cmd";

cmd="docker run -i --rm --name owasp-zap-scanner -u \"$(id -u):$(id -g)\" \
  -v ${CI_PROJECT_DIR}/ci-artifacts/:/zap/wrk/:rw \
  -v /etc/hosts:/etc/hosts:ro \
  ${IMAGES_BASE_PATH}owasp-zap2docker-stable:2.9.0 \
    zap-${SCAN_TYPE}.py -D 15 -m 1 -a -j -T 1 \
      -t ${TARGET_URL} \
      -r owasp-zap-${SCAN_TYPE}-report.html
"; echo ; echo " >>> $cmd"; eval "$cmd" || true;

cmd="cd \"${startDir}\""; echo ; echo " >>> $cmd"; eval "$cmd"
echo -e "\n=== End (duration $(seconds_to_time $SECONDS)) - $(date) - ${HOSTNAME}: ${scriptFullName} ${arguments_main[*]}\n"
