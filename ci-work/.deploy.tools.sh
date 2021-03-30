#!/bin/bash
# shellcheck disable=SC1090 disable=SC1091 disable=SC2039
#
# This file must be identical in: configs/ci-work/, app/ci-work/, restapi/ci-work/, summerwood/ci-work/, sync-server/ci-work/, viewer-html/ci-work/
# and configs/xuver.deployment/.deploy.tools.sh
#
# Set the colors
RED="\033[1;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; PURPLE="\033[1;35m";  WHITE="\033[1;37m"; BLINK="\e[5m"; DEFAULT='\e[0m'; BLUE="\033[1;34m"; echo "BLINK=$BLINK" > /dev/null # fake usage of BLINK to avoid wanrings in VSCode. Actualy BLINK is used in other scripts which loads this file.
#LIGHT_BLUE="\e[94m"; CYAN="\033[1;36m"; RESET="\033[0m"; ORANGE_BG="\e[30;48;5;166m"; BLINK="\e[5m";
# Set the error message
trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR
if [[ -z ${scriptFullName} ]]; then scriptFullName="${BASH_SOURCE[0]}"; fi
echo_and_exit1() { echo ; echo -e "${1} (${2}, ${scriptFullName} / ${BASH_SOURCE[0]})"; echo ; exit 1; }

set_default_env_vars_values() {
  # If you need to change some of these values add the required vars and values to /xuver/hostspecific file

  hostspecific_fullname=${hostspecific_fullname:-"/xuver/hostspecific"};  echo " -> CI_COMMIT_SHORT_SHA=${CI_COMMIT_SHORT_SHA}"
  if [[ -f ${hostspecific_fullname} ]]; then echo "Load vars from ${hostspecific_fullname}"; source "${hostspecific_fullname}"; else echo "File ${hostspecific_fullname} is missing. Skipping it."; fi

  CI_COMMIT_SHORT_SHA=${CI_COMMIT_SHORT_SHA:-"0000aaaa"};     echo " -> CI_COMMIT_SHORT_SHA=${CI_COMMIT_SHORT_SHA}"
  CI_COMMIT_BRANCH=${CI_COMMIT_BRANCH:-""};
  CI_COMMIT_BRANCH=$(echo "${CI_COMMIT_BRANCH}" | tr "[:upper:]" "[:lower:]" | tr "/=+.,:\\\\" "_");    echo " -> CI_COMMIT_BRANCH=${CI_COMMIT_BRANCH}"
  CI_PIPELINE_ID=${CI_PIPELINE_ID:-"0"};                      echo " -> CI_PIPELINE_ID=${CI_PIPELINE_ID}"
  CI_REGISTRY=${CI_REGISTRY:-"registry.dev.xuver.com:4000"};  echo " -> CI_REGISTRY=${CI_REGISTRY}"
  CI_PROJECT_DIR=${CI_PROJECT_DIR:-"$(readlink ../ -f)"};     echo " -> CI_PROJECT_DIR=${CI_PROJECT_DIR}"
  CI_PROJECT_NAME=${CI_PROJECT_NAME:-"$(basename "${CI_PROJECT_DIR}")"};
  CI_PROJECT_NAME=$(echo "${CI_PROJECT_NAME}" | tr "[:upper:]" "[:lower:]");  echo " -> CI_PROJECT_NAME=${CI_PROJECT_NAME}"
  CI_PROJECT_NAMESPACE=${CI_PROJECT_NAMESPACE:-"xuver"};
  CI_PROJECT_NAMESPACE=$(echo "${CI_PROJECT_NAMESPACE}" | tr "[:upper:]" "[:lower:]");                  echo " -> CI_PROJECT_NAMESPACE=${CI_PROJECT_NAMESPACE}"
  CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-"${CI_REGISTRY}/${CI_PROJECT_NAMESPACE}/${CI_PROJECT_NAME}"};  echo " -> CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE}"
  CI_REGISTRY_USER=${CI_REGISTRY_USER:-""};                   echo " -> CI_REGISTRY_USER=${CI_REGISTRY_USER}"
  CI_REGISTRY_PASSWORD=${CI_REGISTRY_PASSWORD:-""};           echo " -> CI_REGISTRY_PASSWORD=*"

  XPROJECT_COMPILER=${XPROJECT_COMPILER:-"${CI_REGISTRY_IMAGE}/compiler"};    echo " -> XPROJECT_COMPILER=${XPROJECT_COMPILER}"
  XPROJECT_RUNNER=${XPROJECT_RUNNER:-"${CI_REGISTRY_IMAGE}/runner"};          echo " -> XPROJECT_RUNNER=${XPROJECT_RUNNER}"
  IMAGES_BASE_PATH=${IMAGES_BASE_PATH:-"${CI_REGISTRY}/${CI_PROJECT_NAMESPACE}/images/"};               echo " -> IMAGES_BASE_PATH=${IMAGES_BASE_PATH}"
  IMAGETAG_PREFIX=${IMAGETAG_PREFIX:-"${CI_PIPELINE_ID}-${CI_COMMIT_BRANCH}-${CI_COMMIT_SHORT_SHA}"};   echo " -> IMAGETAG_PREFIX=${IMAGETAG_PREFIX}"
  IMAGETAG=${IMAGETAG:-"${IMAGETAG_PREFIX}-$(date +%Y%m%d%H%M)"};             echo " -> IMAGETAG=${IMAGETAG}"

  # Load some variables from other stages, builds, or projects
  BUILD_INFO_FILE=${BUILD_INFO_FILE:-"${CI_PROJECT_DIR}/xversion.env"};       echo " -> BUILD_INFO_FILE=${BUILD_INFO_FILE}"
  if [[ -f "${BUILD_INFO_FILE}" ]]; then
    echo "Load vars from ${BUILD_INFO_FILE}";
    grep -v '^#\|^$' "${BUILD_INFO_FILE}";
    source "${BUILD_INFO_FILE}";
  else echo "BUILD_INFO_FILE=${BUILD_INFO_FILE} is missing. Skipping it.";  fi

  if [[ -f "${CI_PROJECT_DIR}/ci-work/projectspecific" ]]; then
    echo "Load vars from ${CI_PROJECT_DIR}/ci-work/projectspecific";
    grep -v '^#\|^$' "${CI_PROJECT_DIR}/ci-work/projectspecific";
    source "${CI_PROJECT_DIR}/ci-work/projectspecific";
  else echo "${CI_PROJECT_DIR}/ci-work/projectspecific is missing. Skipping it.";  fi

} # set_default_env_vars_values

# Set default env vars
set_default_env_vars_values

get_hostspecific() {
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR

  echo "--- Process ${hostspecific_fullname} file"

  HOST_IP=""
  source "${hostspecific_fullname}"
  if [[ -z "$HOST_IP" ]]; then
    echo_and_exit1 "${hostspecific_fullname} misses HOST_IP variable." $LINENO
  fi
  if ! ip addr | grep -q " ${HOST_IP}/"
  then
    echo_and_exit1 "Probably wrong value for HOST_IP=$HOST_IP in the file ${hostspecific_fullname}. Compare it with 'ip addr'." $LINENO
  fi
  echo -e "\t ... ${GREEN}done${DEFAULT}"
} # get_hostspecific

prepare_config_files() {
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR

  # Initialize vars which a going to be taken from *.env files - it is done only to avoid warnings from VSCode.
  db_password=; ingenico_sha_in=; ingenico_sha_out=; smtp_password=;

  echo "--- Get config files from templates"
  cp -v config-templates/.env.template ./.env
  cp -v config-templates/xuver.env.template ./xuver.env

  echo "--- Adjust CONFIG files"
  replace_var_values "${hostspecific_fullname}" ./.env
  replace_var_values "${hostspecific_fullname}" ./xuver.env
  envsubst_file ./.env ./.env
  envsubst_file ./xuver.env ./xuver.env
  envsubst_file ./.env ./xuver.env
  envsubst_file ./xuver.env ./.env
  source ./.env
  source ./xuver.env
  echo -e "\t ... ${GREEN}done${DEFAULT}"

  folders="${POSTGRES_DATA_DIR} ${POSTGRES_BACKUPS_DIR} ${FILE_STORAGE_DIR} ${DOWNLOADS_DIR} ${SECRETS_DIR} ${TRAEFIK_CONFIG}rules/ ${TRAEFIK_LOGS} ${SHARED_FOLDER} ${COTURN_DATA} ${COTURN_LOGS} ${API_LOGS}"
  echo "--- Create persistent folders: ${folders}"
  cmd="mkdir -pv ${folders}"; eval "$cmd"
  echo -e "\t ... ${GREEN}done${DEFAULT}"

  echo "--- Copying and adjust Traefik config files"
  cp -v config-templates/traefik.toml.template "${TRAEFIK_CONFIG}"traefik.toml
  cp -v config-templates/traefik.rule.*.template "${TRAEFIK_CONFIG}"rules/
  for file in "${TRAEFIK_CONFIG}"rules/*.template ; do
    mv "${file}" "${file:0:-9}"
  done

  # If not DEV server, then remove DEV specific traefik files
  if [[ "${XUVER_DOMAIN}" != "dev.xuver.com" ]]; then
    for file in \
      ${TRAEFIK_CONFIG}rules/traefik.rule.jenkins.toml \
      ; do
      rm -fv "${file}"
    done
  fi

  envsubst_file ./.env "${TRAEFIK_CONFIG}"traefik.toml
  envsubst_file ./xuver.env "${TRAEFIK_CONFIG}"traefik.toml
  for file in "${TRAEFIK_CONFIG}"rules/*.toml ; do
    envsubst_file ./.env "${file}"
    envsubst_file ./xuver.env "${file}"
  done

  echo -e "\t ... ${GREEN}done${DEFAULT}"

  echo "--- Copying certificates to ${SECRETS_DIR}"
  if [[ -f "./config-templates/${XUVER_DOMAIN}.crt.template" && -f "./config-templates/${XUVER_DOMAIN}.key.template" ]]; then
    echo "Certificates are available as template. Copying them ... "
    cp -v ./config-templates/"${XUVER_DOMAIN}".crt.template "${SECRETS_DIR}${XUVER_DOMAIN}.crt"
    cp -v ./config-templates/"${XUVER_DOMAIN}".key.template "${SECRETS_DIR}${XUVER_DOMAIN}.key"
  else
    echo -e "${YELLOW}Certificates are not available as template.${DEFAULT} They will BE generated at startup."
  fi
  echo -e "\t ... ${GREEN}done${DEFAULT}"

  echo "--- Creating other secret files"
  echo " - ${SECRETS_DIR}db_password"
  echo -n "${db_password}" > "${SECRETS_DIR}db_password"
  echo " - ${SECRETS_DIR}ingenico_sha_in"
  echo "${ingenico_sha_in}" > "${SECRETS_DIR}ingenico_sha_in"
  echo " - ${SECRETS_DIR}ingenico_sha_out"
  echo "${ingenico_sha_out}" > "${SECRETS_DIR}ingenico_sha_out"
  echo " - ${SECRETS_DIR}smtp_password"
  echo "${smtp_password}" > "${SECRETS_DIR}smtp_password"
  echo -e "\t ... ${GREEN}done${DEFAULT}"
} # prepare_config_files

remove_folders() {
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR

  echo -e "--- ${PURPLE}Remove persistent folders too${DEFAULT}"
  sudo rm -rfd "${XUVER_ROOT_DIR}" "${POSTGRES_BACKUPS_DIR}" "${FILE_STORAGE_DIR}" "${DOWNLOADS_DIR}" "${SECRETS_DIR}" "${SHARED_FOLDER}" "${COTURN_DATA}" "${COTURN_LOGS}"
  echo -e "\t ... ${GREEN}done${DEFAULT}"
} # remove_folders

replace_var_values() { # Usage: replace_var_values "${HOSTSPECIFIC}" .env
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR

  sourceFile="$1"
  targetFile="$2"
  if [[ ! ( -f ${sourceFile} && -f ${targetFile}) ]]; then echo_and_exit1 "ERROR! Source or target file does not exists." ${LINENO}; fi;

  echo "--- Substitute VAR=VALUE pairs from ${sourceFile} to ${targetFile}"
  source "${sourceFile}"
  vars=$(grep "=" "${sourceFile}" | grep -v "^#" | cut -d "=" -f1)
  if [ "${vars}" ]; then
    echo -e "${RED}-- Override:${DEFAULT}"
    for v in $vars; do
      echo "$v=${!v}";
      sed "/^\b$v\b=/ c$v=${!v}" -i "$targetFile"
    done;
    echo -e "\t ... ${GREEN}done${DEFAULT}"
  fi
} # replace_var_values

envsubst_file() { # Usage: envsubst_file fromEnvFile targetConfigFile
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR

  envFile="$1"
  targetFile="$2"
  if [[ ! ( -f ${envFile} && -f ${targetFile}) ]]; then echo_and_exit1 "ERROR! Source or target file does not exists." ${LINENO}; fi;

  echo -en "\t--- ENVSUBST variables from $envFile into $targetFile"
  source "${envFile}"

  vars=$(grep "=" "${envFile}" | grep -v "^#" | cut -d "=" -f1)
  if [ "$vars" ]; then
    for v in $vars; do
      if grep -q "${v}" "${targetFile}"; then
        sed -e "s|\$$v|${!v}|g" -e "s|\${$v}|${!v}|g" -i "${targetFile}"
      fi
    done
  fi
  echo -e "\t ... ${GREEN}done${DEFAULT}"
} # envsubst_file

etc_hosts_config() {
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR

  hosts="$1"
  host_ip="$2"

  etc_hosts_config_clean "$hosts"

  echo -e "--- Add records ${YELLOW}${hosts}${DEFAULT} to ${YELLOW}/etc/hosts${DEFAULT} "

  if [[ "${XUVER_DOMAIN}" == +("xuver.com"|"dev.xuver.com") ]]; then
  # if [[ "${XUVER_DOMAIN}" =~ ("xuver.com"|"dev.xuver.com") ]]; then
    echo -e "Domain ${YELLOW}${XUVER_DOMAIN} is public${DEFAULT}. Skipping this step."
  else
    hosts1=$(echo "$hosts" | tr "|" " ")
    for h in $hosts1; do
      echo "${host_ip} ${h}" | sudo tee -a /etc/hosts
    done
  fi
  echo "    Grepping /etc/hosts ... "
  grep -E "${hosts}" /etc/hosts || true
  echo -e "\t ... ${GREEN}done${DEFAULT}"
} # etc_hosts_config

etc_hosts_config_clean() {
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR

  hosts="$1"
  echo -e "--- Remove ${YELLOW}${hosts}${DEFAULT} from ${YELLOW}/etc/hosts${DEFAULT}"
  grep_res=$(grep -v "^#" /etc/hosts | grep -E "${hosts}") || true
  if [[ -n "$grep_res" ]]; then
    echo -e "${RED}SUDO access will be required${DEFAULT}"
    hosts1=$(echo "$hosts" | tr "|" " ")
    for h in $hosts1; do
      sudo sed -i "/\s${h}\b/d" /etc/hosts
    done
    echo "    Grepping /etc/hosts ... "
    grep -v "^#" /etc/hosts | grep -E "${hosts}" || true
    echo -e "\t ... ${GREEN}done${DEFAULT}"
  else
    echo "/etc/hosts is clean. Nothing to do. "
  fi
  echo -e "\t ... ${GREEN}done${DEFAULT}"
} # etc_hosts_config_clean

generate_self_signed_certificate() {
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR

  domain=${1}
  echo "--- Going to generate self-signed certificates for \"${domain}\" in the folder ${SECRETS_DIR}"
  mkdir -pv "${SECRETS_DIR}"

  if [[ -f "${SECRETS_DIR}${domain}.crt" && -f "${SECRETS_DIR}${domain}.key" ]]; then
    echo -e "${GREEN}Certificates are available in ${SECRETS_DIR}.${DEFAULT} Skipping this step."
  elif [[ "${domain}" == +("xuver.com"|"dev.xuver.com") ]]; then
    echo_and_exit1 "${RED}ERROR! Domain ${domain} is public.${DEFAULT} Certificates must be available in ./config-templates." ${LINENO}
  else
      cd "${SECRETS_DIR}" || exit 1
      echo "--- Generating self-signed certificates ... (PWD=$PWD)"
      openssl genrsa -des3 -passout pass:'xuver' -out "${domain}.pass.key" 2048
      openssl rsa -passin pass:'xuver' -in "${domain}.pass.key" -out "${domain}.key"
      rm -v "${domain}.pass.key"
      openssl req -new -key "${domain}.key" -out "${domain}.csr" -subj "/C=MD/ST=Chisinau/L=Chisinau/O=XUVER/OU=DEVTeam/CN=*.${domain}"
      openssl x509 -req -days 3650 -in "${domain}.csr" -signkey "${domain}.key" -out "${domain}.crt"
      echo -e "\t ... ${GREEN}done${DEFAULT}"
  fi

  echo -e "\t ... ${GREEN}done${DEFAULT}"
} # generate_self_signed_certificate

docker_login_and_pull_images() {
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR
  # Required variables:
  #     REGISTRY_PREFIX=registry.dev.xuver.com:4000/
  #     REGISTRY_USER=<username>
  #     REGISTRY_PSW=<echo password | base64>
  login_res="-"
  function docker_login_only() {
      if [[ -n "${REGISTRY_USER}" ]]; then
          if [[ -n "${REGISTRY_PSW}" ]]; then
              login_res=$(echo "${REGISTRY_PSW}" | base64 -d | docker login -u "${REGISTRY_USER}" --password-stdin "${REGISTRY_PREFIX}" 2>&1 | grep -vi "WARNING\|Configure a credential helper\|https://docs.docker.com/engine/reference/commandline/login/#credentials-store")
          elif [[ -n "${REGISTRY_PSW_PLAINTEXT}" ]]; then
              login_res=$(echo "${REGISTRY_PSW_PLAINTEXT}" | docker login -u "${REGISTRY_USER}" --password-stdin "${REGISTRY_PREFIX}" 2>&1 | grep -vi "WARNING\|Configure a credential helper\|https://docs.docker.com/engine/reference/commandline/login/#credentials-store")
          else
              login_res="Registry Password is null. Continue without authentication."
          fi
      else
          login_res="Registry Login is null. Continue without authentication."
      fi
  }

  echo "-- Checking if it is needed to pull any image..."
  allImages=$(docker-compose config | grep image)
  allImages=${allImages//"image: "/}
  needPull=""
  for image in ${allImages}; do
    if [[ -z "$(docker images -q "${image}" 2> /dev/null)" ]]; then
      echo " ... localy missing - ${image}";
      needPull="${needPull} ${image}";
    fi
  done

  echo "-- Login to Docker Registry (${REGISTRY_PREFIX})"
  if [[ -n "$needPull" ]]; then
      docker_login_only || true
      if [[ "${login_res}" != *"Login Succeeded"* && "${login_res}" != *"Continue without authentication."* ]]; then
          echo -e "${RED}ERROR! Deployment failed${DEFAULT}: ${login_res} ($LINENO $0)";
          exit 1;
      else
          echo -e "\t ... ${login_res}"
      fi

      echo "-- Pulling missing Docker Images (${needPull})"
      for image in ${needPull}; do
          docker pull "${image}";
          res=$?; if [[ ${res} != 0 ]]; then echo -e "${RED}ERROR! Deployment failed${DEFAULT}: $LINENO $0"; exit $res; fi
      done
  else
      echo -e " ... ${GREEN}All required images are available localy.${DEFAULT} No need to login and pull images from Docker Registry."
  fi
} # docker_login_and_pull_images

postgres_post_deployment() {
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR

  echo "--- Set ownership on used folders"
  docker-compose exec -T -u root postgres chown -v postgres:postgres /backups/ -R | grep "'/backups/'"
  echo -e "\t ... ${GREEN}done${DEFAULT}"

  echo "--- Repopulate table plugins"
  if [[ -f ${DOWNLOADS_DIR}/xuver-plugins.sql ]]; then
    cmd="cp -vf ${DOWNLOADS_DIR}xuver-plugins.sql ${SHARED_FOLDER}xuver-plugins.sql"; echo ; echo " >>> $cmd"; eval "$cmd"
    envsubst_file ./.env "${SHARED_FOLDER}xuver-plugins.sql"
    envsubst_file ./xuver.env "${SHARED_FOLDER}xuver-plugins.sql"
    cmd="docker-compose exec -T postgres psql xuver xuver -f /shared_folder/xuver-plugins.sql"; echo ; echo " >>> $cmd"; eval "$cmd"
    cmd="rm -vf ${SHARED_FOLDER}xuver-plugins.sql"; echo ; echo " >>> $cmd"; eval "$cmd"
  else
    echo "File on the host ${DOWNLOADS_DIR}xuver-plugins.sql is missing. Skipping this step."
  fi
  echo -e "\t ... ${GREEN}done${DEFAULT}"

} # postgres_post_deployment

enable_xuver_user() {
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR

  xuser="$1"
  echo "--- Activate user $xuser to be able to authenticate"
  # Check if table exists docker-compose exec -T postgres psql -c "SELECT EXISTS (select * from information_schema.tables where table_name = 'users')" xuver xuver
  sql="select id from users where email='${xuser}'"
  echo " > $sql"
  xu_id=$(docker-compose exec -T postgres psql -c "${sql}" xuver xuver | grep -v "id\|--------\| row" | tr -d " " | tr -d "\n")
  echo "$xu_id"
  sql="update users set active = '1' where email = '${xuser}';"
  echo " > $sql"
  cmd="docker-compose exec -T postgres psql -c \"${sql}\" xuver xuver"; echo " >>> $cmd"; eval "$cmd" || true

  sql="update oauth_clients SET id = 'app' where user_id = '${xu_id}' and redirect_uri = 'https://app.${XUVER_DOMAIN}';"
  echo " > $sql"
  cmd="docker-compose exec -T postgres psql -c \"${sql}\" xuver xuver"; echo " >>> $cmd"; eval "$cmd" || true
  if [[ ${xuser} == "xuver_admin@xuver.com" ]]; then
    echo -e "\n    NOTE: If no configurations made in XUVER deployment, default credentials are:"
    echo -e "\n               username: xuver_admin@xuver.com, password: zaq1@WSX"
  fi
  echo -e "\t ... ${GREEN}done${DEFAULT}"
} # enable_xuver_user

check_docker_container_health() { # Usage: check_docker_container_health <container name or id>
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR
  container1=$1

  timeout=${DOCKER_HEALTHCHECK_TIMEOUT_SECS:-100}
  interval=${DOCKER_HEALTHCHECK_INTERVAL_SECS:-5}
  iterations=$(( timeout / interval ))
  echo -e "-- Checking health of container ${BLUE}${container1}${DEFAULT} (every ${interval} secs max ${iterations} iterations):";
  healthcheck=$(docker inspect "${container1}" --format "{{.Config.Healthcheck}}")
  if [[ $healthcheck == "<nil>" ]]; then
    echo "Warning! Healthcheck is not configured. Hope container is ok."
  else
    i=0
    while [[ i++ -le ${iterations} ]]; do
      res1=$(docker inspect --format '{{.State.Health.Status}}' "${container1}")
      echo " - iteration $i result: $res1"
      if [[ $res1 == "healthy" ]]; then i=$(( iterations + 1 )); else sleep 5; fi
    done
    if [[ $res1 == "healthy" ]]; then echo -e "${GREEN}Container ${container1} is HEALTHY!${DEFAULT}";
    else echo_and_exit1 "ERROR! ${container1} did not get ready in time:" $LINENO; fi
  fi
} # check_docker_container_health

get_var_value() {
  trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR

  # The logic is:
  # 1) get the var from arguments
  # 2) if not exists as argument, get the var from .env file
  # 3) if not exists as argument and neither in .env ask user to input a value
  # Usage:
  #    get_var_value --var_name=ACTION --val_regex="s|t|i" --var_value_hint="s=start,t=stop,u=update" --skip_env_file $@
  #    get_var_value --var_name=ACTION --val_regex="b|f|p|bp|fp" --var_value_hint="b=build,f=force_rebuild,p=push" --var_default_value="b" "${arguments_main[*]}"

  var_name="";  val_regex="";  var_value_hint="";  var_value="";  var_default_value="";  arguments="";  skip_env_file=false
  is_var_in_arguments=false
  is_var_in_env_file=false;

  arguments_get_var_value=( "$@" )
  for arg in ${arguments_get_var_value[*]}; do  # split required arguments and values
    case $arg in
      --var_name=*)          var_name="${arg#*=}"         ;;
      --val_regex=*)         val_regex="${arg#*=}"        ;;
      --var_value_hint=*)    var_value_hint="${arg#*=}"   ;;
      --var_default_value=*) var_default_value="${arg#*=}";;
      --skip_env_file)       skip_env_file=true           ;;
      *)   arguments="$arguments ${arg}";;
    esac
  done
  # 1) get the var from arguments
  for arg in $arguments; do  # get $var_name from arguments, if present
    if [[ $arg == "--${var_name}="* ]]; then  var_value="${arg#*=}"; is_var_in_arguments=true; fi
  done

  if [[ ${is_var_in_arguments} == false && ${skip_env_file} == false ]]; then
    # 2) if not exists as argument get the var from .env file
    test -f ".env" && grep "^${var_name}=" ".env" && is_var_in_env_file=true;
    if [[ ${is_var_in_env_file} == true ]]; then get_var_from_file --var_name="${var_name}" --var_file=".env"; var_value=${!var_name}; fi
  fi

  if [[ ${is_var_in_arguments} == false && ${is_var_in_env_file} == false ]]; then
    # 3) if not exists as argument and neither in .env file, ask user to input a value
    while [[ -z ${var_value} || ${var_value} != $(echo "$var_value" | grep -Eo "${val_regex}" | tr -d "\n") ]]; do
      echo -e "\n--Variable ${var_name} is not present as argument and not present in .env file. Asking a value: ${YELLOW}${var_value_hint}${DEFAULT}."
      echo -ne "  Input value for ${YELLOW}${var_name}${DEFAULT} (regex=${WHITE}${val_regex}${DEFAULT}, default=${YELLOW}${var_default_value}${DEFAULT}, Press <Enter> for default): "
      read -r var_value;
      if [[ -z ${var_value} ]]; then var_value=${var_default_value}; fi
    done
  fi
  eval "${var_name}=${var_value}"
  echo " -> ${var_name}=${var_value}"
} # get_var_value

get_var_from_file() { # Usage: get_var_from_file --var_name="${var_name}" --var_file=".env"
  var_name=""
  var_file=""
  args=( "$@" )
  for arg in ${args[*]}; do  # split required arguments and values
    case $arg in
      --var_name=*)  var_name="${arg#*=}" ;;
      --var_file=*)  var_file="${arg#*=}" ;;
    esac
  done
  if [[ -f "${var_file}" && -n ${var_name} ]]; then
    eval "$(grep ^"${var_name}"= "${var_file}")"
  fi
  echo "${var_file} |-> ${var_name}=${!var_name}"
} # get_var_from_file

upsert_var_into_file() { # Usage: upsert_var_into_file --var_name=HOSTSPECIFIC --var_value="${HOSTSPECIFIC}" --var_file=.env
  trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR

  var_name="";  var_value="";  var_file="";
  args=( "$@" )
  for arg in ${args[*]}; do  # split required arguments and values
    case $arg in
      --var_name=*)  var_name="${arg#*=}"  ;;
      --var_value=*) var_value="${arg#*=}" ;;
      --var_file=*)  var_file="${arg#*=}"  ;;
    esac
  done
  touch "${var_file}"
  sed -i "/^${var_name}=.*/d" "${var_file}"
  echo "${var_name}=${var_value}" >> "${var_file}"

  # grep "^${var_name}=" "${var_file}" 1>/dev/null \
  #   && sed "s|^${var_name}=.*|${var_name}=${var_value}|" -i "${var_file}" \
  #   || echo "${var_name}=${var_value}" >> "${var_file}"
  echo "${var_file} <-| ${var_name}=${var_value}"
} # upsert_var_into_file

upsert_var_into_json_file() { # Usage: upsert_var_into_json_file --var_name=.database.host --var_value="${HOSTSPECIFIC}" --var_file=file.json
  trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR

  var_name="";  var_value="";  var_file="";
  args=( "$@" )
  for arg in ${args[*]}; do  # split required arguments and values
    case $arg in
      --var_name=*)  var_name="${arg#*=}"  ;;
      --var_value=*) var_value="${arg#*=}" ;;
      --var_file=*)  var_file="${arg#*=}"  ;;
    esac
  done
  if [[ ! -f "${var_file}" ]]; then echo "{}" > "${var_file}"; fi
  temp_file=$(mktemp)
  jq -e "${var_name}=\"${var_value}\"" "${var_file}" > "$temp_file"
  mv -f "$temp_file" "${var_file}"

  out=$(jq -ec "{\"${var_name}\":${var_name}}" "${var_file}")
  echo "${var_file} <-| ${out}"
#  jq -ec '{".database.host": .database.host}' "${var_file}"
} # upsert_var_into_json_file

follow_the_logs() {
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR

  echo ;
  echo "        Following the logs ..."
  echo " (press Ctrl+C anytime to quit monitoring the logs - this will not stop started components)"
  echo ;
  sleep 3
  docker-compose logs -f
} # monitor_logs

seconds_to_time() { # Usage seconds_to_time $SECONDS
  local SecondsEndCount=$(( $1 % 60 ))
  local MinutesNumber=$(( $1 / 60 ))
  local MinutesEndCount=$(( MinutesNumber % 60 ))
  local HoursEndCount=$(( MinutesNumber / 60 ))
  test ${#SecondsEndCount} -ne 2 && SecondsEndCount="0${SecondsEndCount}"
  test ${#MinutesEndCount} -ne 2 && MinutesEndCount="0${MinutesEndCount}"
  test ${#HoursEndCount} -ne 2   && HoursEndCount="0${HoursEndCount}"
  echo "${HoursEndCount}:${MinutesEndCount}:${SecondsEndCount}"
}

check_root_access() {
  trap 'echo_and_exit1 "ERROR! Something went wrong." ${LINENO}' ERR

  echo "--- Checking permissions"
  if [[ $(whoami) == "root" ]]; then
    echo "Running as root."
  else
    echo_and_exit1 "ERROR! ROOT/SUDO access required.

      $0 MUST be run as ROOT. Use \"sudo bash $0\" : ${LINENO}, ${scriptFullName}
" ${LINENO}
  fi
} # check_root_access

ci_deploy_down() {
  trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR

  scriptFullPath=${scriptFullPath:-"/tmp"}   # Assign a value, just to avoid warnings in compiler
  echo -e "\n--- Cleaning the field\n"
  if [[ -f ${CI_PROJECT_DIR}/.env ]]; then
    cmd="docker-compose --project-directory ${CI_PROJECT_DIR} -f ${scriptFullPath}/all-docker-compose.yaml rm -fsv"; echo ; echo " >>> $cmd"; eval "$cmd";
    cmd="docker-compose --project-directory ${CI_PROJECT_DIR} -f ${scriptFullPath}/all-docker-compose.yaml down --remove-orphans --volumes"; echo ; echo " >>> $cmd"; eval "$cmd";
  fi
}

apt-install-required-tools() {
  trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR
  tools_pkgs="nano mc dos2unix gnupg2 pass curl wget jq yq telnet netcat unzip postgresql-client iputils-ping git";
  tools_cmds="nano mc dos2unix gpg    pass curl wget jq yq telnet netcat unzip psql              ping         git";

  todo="false"
  for cmd in ${tools_cmds}; do
    if [[ -z "$(command -v "${cmd}")" ]]; then
      echo " - ${cmd} does not exists";
      todo="true"; fi
  done

  if [[ "${todo}" == "true" ]]; then
    # Yaml parser yq, https://github.com/mikefarah/yq.
    cmd="sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CC86BB64"; echo ; echo " >>> $cmd"; eval "$cmd";
    cmd="sudo add-apt-repository ppa:rmescandon/yq"; echo ; echo " >>> $cmd"; eval "$cmd";
    cmd="sudo apt-get update"; echo ; echo " >>> $cmd"; eval "$cmd";

    cmd="sudo apt-get install -y ${tools_pkgs}"; echo ; echo " >>> $cmd"; eval "$cmd";

  fi
}

00-prepare.sh_help() {
  echo "
========================= USAGE =========================
  Usage: $ bash ci-work/00-prepare.sh [--ACTION=b|p]

  Examples:
  1) Start and use the wizard
      bash ci-work/00-prepare.sh
  2) Build and push Docker images used in CI
      bash ci-work/00-prepare.sh --ACTION=bp
  3) Build only :
      bash ci-work/00-prepare.sh --ACTION=b
  4) Push only
      bash ci-work/00-prepare.sh --ACTION=p
=========================================================
"
}

01-compile.sh_help() {
  echo "
========================= USAGE =========================
  This compiles current project. The output folder is ${BUILD_DIR}.

  Usage: $ bash ci-work/01-compile.sh [--CLEAN_BUILD_DIR=y|n]

  Examples:
  1) Start and use the wizard
      bash ci-work/01-compile.sh
  2) Remove the output folder ${BUILD_DIR} and compile
      bash ci-work/01-compile.sh --CLEAN_BUILD_DIR=y
=========================================================
"
}

02-tests.sh_help() {
  echo "
========================= USAGE =========================
  Run the tests using compiled files in ${BUILD_DIR}.

  Usage: $ bash ci-work/02-tests.sh

  Examples:
  1) No arguments are required
      bash ci-work/02-tests.sh
=========================================================
"
}

03-build.sh_help() {
  echo "
========================= USAGE =========================
  This builds the docker image with compiled files.

  Usage: $ bash ci-work/03-build.sh [--ACTION=b|p]

  Examples:
  1) Start and use the wizard
      bash ci-work/03-build.sh
  2) Build docker image and push to Docker Registry
      bash ci-work/03-build.sh --ACTION=bp
=========================================================
"
}

04-deploy.sh_help() {
  echo "
========================= USAGE =========================
  This deploys XUVER to LOCALHOST or to a remote host. For remote host use argument --TARGET=<remote-user>@<remote-host-address>.

  Usage: $ bash ci-work/04-deploy.sh [--TARGET=.] [--ACTION=[t|i|u|s] ] [--COMPONENTS_TO_UPDATE=[i|v|a|s|w] ] [--XUVER_API_IMAGETAG=latest] [--XUVER_VIEWER_IMAGETAG=latest] [--XUVER_APP_IMAGETAG=latest] [--XUVER_SYNC_IMAGETAG=latest] [--XUVER_SUMMERWOOD_IMAGETAG=latest] [--COMPONENTS=[p|i|v|a|s|w] ] [--SILENT]

  Examples:
  1) Stop all XUVER components:
      bash ci-work/04-deploy.sh --TARGET=. --ACTION=t
  2) Start all XUVER components:
      bash ci-work/04-deploy.sh --TARGET=. --ACTION=s  --COMPONENTS=pivaswd --SILENT
  3) Get the latest deployment scripts and start all XUVER components
      bash ci-work/04-deploy.sh --TARGET=. --ACTION=is --COMPONENTS=pivaswd --SILENT
  4) Get the latest deployment scripts, update API and start all XUVER components
      bash ci-work/04-deploy.sh --TARGET=. --ACTION=ius --COMPONENTS_TO_UPDATE=i --XUVER_API_IMAGETAG=latest --COMPONENTS=pivaswd --SILENT
  5) Get the latest deployment scripts, update all XUVER components and start all XUVER components
      bash ci-work/04-deploy.sh --TARGET=. --ACTION=tius --COMPONENTS_TO_UPDATE=ivaswd --XUVER_API_IMAGETAG=latest --XUVER_VIEWER_IMAGETAG=latest --XUVER_APP_IMAGETAG=latest --XUVER_SYNC_IMAGETAG=latest --XUVER_SUMMERWOOD_IMAGETAG=latest --XUVER_DOWNLOADS_IMAGETAG=latest --COMPONENTS=pivaswd --VOLUMES --RMI --SILENT
=========================================================
"
}
