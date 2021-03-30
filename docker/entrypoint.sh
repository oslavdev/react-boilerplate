#!/usr/bin/env bash

TEMPLATE='/etc/nginx/conf.d/nginx.no-ssl.conf.template'
if [ "${XUVER_APP_SSL_ENABLED}" == "yes" ]; then
    TEMPLATE='/etc/nginx/conf.d/nginx.ssl.conf.template'
fi

envsubst '${XUVER_APP_HOST},${XUVER_CERT_PATH},${XUVER_CERT_KEY_PATH}' \
    < "${TEMPLATE}" \
    > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;' "$@"
