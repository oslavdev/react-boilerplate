#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039

startDir="$PWD";
scriptFullPath="$(dirname "$(readlink -f "$0")")";
scriptBaseName="$(basename "$0")";
scriptFullName="${scriptFullPath}/${scriptBaseName}";
trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR
echo_and_exit1() { echo ; echo -e "${1} (${2}, ${scriptFullName} / ${BASH_SOURCE[0]})"; echo ; exit 1; }

echo ; echo "== Begin - $(date) - ${HOSTNAME}: ${scriptFullName}"

cmd="WORKSPACE=$(readlink -f "${scriptFullPath}"/..)"; echo ; echo " >>> $cmd"; eval "$cmd"

echo -e "\n-- Running the tests and coverage"
cmd="npm run test -- --coverage --collectCoverageFrom='src/**/*.js' --collectCoverageFrom='!src/root.js' --coverageDirectory='ci-artifacts/tests-coverage' --coverageReporters='text' | tee ${PWD}/ci-artifacts/tests-coverage.txt"; echo ; echo " >>> $cmd"; eval "$cmd"

echo -e "\n-- Quality scan: Retire.js - Scan a web app or node app for use of vulnerable JavaScript libraries and/or node modules."
cmd="retire --path ${PWD}/ --outputformat=text --outputpath ${PWD}/ci-artifacts/retire-results.txt"; echo ; echo " >>> $cmd"; eval "$cmd" || true

echo -e "\n-- Quality scan: Searching for unnamed exports"
cmd="grep -rnE 'export default connect\(' ${PWD}/src/ | tee ${PWD}/ci-artifacts/unnamed-exports.txt"; echo ; echo " >>> $cmd"; eval "$cmd" || true
cmd="grep -rnE 'export default withStyles\(' ${PWD}/src/ | tee -a ${PWD}/ci-artifacts/unnamed-exports.txt"; echo ; echo " >>> $cmd"; eval "$cmd" || true

echo -e "\n-- Quality scan: NodeJSscan - Static security code scanner (SAST) for Node.js"
cmd="njsscan ${PWD}/ --output ${PWD}/ci-artifacts/njsscan-results.txt"; echo ; echo " >>> $cmd"; eval "$cmd" || true

cmd="cd \"${startDir}\""; echo ; echo " >>> $cmd"; eval "$cmd"
echo ; echo "== End - $(date) - ${HOSTNAME}: ${scriptFullName}"
