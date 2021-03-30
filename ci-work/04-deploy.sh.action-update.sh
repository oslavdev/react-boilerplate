#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039
#
# This file must be identical in: configs/ci-work/, app/ci-work/, restapi/ci-work/, summerwood/ci-work/, sync-server/ci-work/, viewer-html/ci-work/
#

trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR
echo_and_exit1() { echo ; echo -e "${1} (${2}, ${BASH_SOURCE[0]})"; echo ; exit 1; }

echo ; echo "-- Updating scripts  ${USER}@${HOSTNAME}:/xuver/xuver.deployment/"
arguments_main=( "$@" )

COMPONENTS_TO_UPDATE="";
XUVER_API_IMAGETAG="";
XUVER_VIEWER_IMAGETAG="";
XUVER_APP_IMAGETAG="";
XUVER_SYNC_IMAGETAG="";
XUVER_SUMMERWOOD_IMAGETAG="";
XUVER_DOWNLOADS_IMAGETAG="";

for arg in ${arguments_main[*]}; do
  case $arg in
    --COMPONENTS_TO_UPDATE=*) COMPONENTS_TO_UPDATE="${arg#*=}";;
  esac
done
for arg in ${arguments_main[*]}; do
  case $arg in
    --XUVER_API_IMAGETAG=*)     if [[ $COMPONENTS_TO_UPDATE == *"i"* ]]; then XUVER_API_IMAGETAG="${arg#*=}";   fi  ;;
    --XUVER_VIEWER_IMAGETAG=*)  if [[ $COMPONENTS_TO_UPDATE == *"v"* ]]; then XUVER_VIEWER_IMAGETAG="${arg#*=}";fi  ;;
    --XUVER_APP_IMAGETAG=*)     if [[ $COMPONENTS_TO_UPDATE == *"a"* ]]; then XUVER_APP_IMAGETAG="${arg#*=}";   fi  ;;
    --XUVER_SYNC_IMAGETAG=*)    if [[ $COMPONENTS_TO_UPDATE == *"s"* ]]; then XUVER_SYNC_IMAGETAG="${arg#*=}";  fi  ;;
    --XUVER_SUMMERWOOD_IMAGETAG=*)  if [[ $COMPONENTS_TO_UPDATE == *"w"* ]]; then XUVER_SUMMERWOOD_IMAGETAG="${arg#*=}"; fi  ;;
    --XUVER_DOWNLOADS_IMAGETAG=*)   if [[ $COMPONENTS_TO_UPDATE == *"d"* ]]; then XUVER_DOWNLOADS_IMAGETAG="${arg#*=}"; fi  ;;
    *) ;;
  esac
done

hostspecific_fullname="/xuver/hostspecific";

if [[ -n $XUVER_API_IMAGETAG ]]; then
  cmd="sed -i '/^XUVER_API_IMAGETAG=.*/d' ${hostspecific_fullname}"; echo ; echo " >>> $cmd"; eval "$cmd";
  cmd="echo XUVER_API_IMAGETAG=${XUVER_API_IMAGETAG} >> ${hostspecific_fullname}"; echo ; echo " >>> $cmd"; eval "$cmd";
fi
if [[ -n $XUVER_VIEWER_IMAGETAG ]]; then
  cmd="sed -i '/^XUVER_VIEWER_IMAGETAG=.*/d' ${hostspecific_fullname}"; echo ; echo " >>> $cmd"; eval "$cmd";
  cmd="echo XUVER_VIEWER_IMAGETAG=${XUVER_VIEWER_IMAGETAG} >> ${hostspecific_fullname}"; echo ; echo " >>> $cmd"; eval "$cmd";
fi
if [[ -n $XUVER_APP_IMAGETAG ]]; then
  cmd="sed -i '/^XUVER_APP_IMAGETAG=.*/d' ${hostspecific_fullname}"; echo ; echo " >>> $cmd"; eval "$cmd";
  cmd="echo XUVER_APP_IMAGETAG=${XUVER_APP_IMAGETAG} >> ${hostspecific_fullname}"; echo ; echo " >>> $cmd"; eval "$cmd";
fi
if [[ -n $XUVER_SYNC_IMAGETAG ]]; then
  cmd="sed -i '/^XUVER_SYNC_IMAGETAG=.*/d' ${hostspecific_fullname}"; echo ; echo " >>> $cmd"; eval "$cmd";
  cmd="echo XUVER_SYNC_IMAGETAG=${XUVER_SYNC_IMAGETAG} >> ${hostspecific_fullname}"; echo ; echo " >>> $cmd"; eval "$cmd";
fi
if [[ -n $XUVER_SUMMERWOOD_IMAGETAG ]]; then
  cmd="sed -i '/^XUVER_SUMMERWOOD_IMAGETAG=.*/d' ${hostspecific_fullname}"; echo ; echo " >>> $cmd"; eval "$cmd";
  cmd="echo XUVER_SUMMERWOOD_IMAGETAG=${XUVER_SUMMERWOOD_IMAGETAG} >> ${hostspecific_fullname}"; echo ; echo " >>> $cmd"; eval "$cmd";
fi
if [[ -n $XUVER_DOWNLOADS_IMAGETAG ]]; then
  cmd="sed -i '/^XUVER_DOWNLOADS_IMAGETAG=.*/d' ${hostspecific_fullname}"; echo ; echo " >>> $cmd"; eval "$cmd";
  cmd="echo XUVER_DOWNLOADS_IMAGETAG=${XUVER_DOWNLOADS_IMAGETAG} >> ${hostspecific_fullname}"; echo ; echo " >>> $cmd"; eval "$cmd";
fi

echo ; echo "-- End"
