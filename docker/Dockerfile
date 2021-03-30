ARG XPROJECT_RUNNER="nginx:1.15.2"
FROM ${XPROJECT_RUNNER}

ENV XUVER_APP_HOST='app.xuver.local' \
  XUVER_APP_PORT=80 \
  XUVER_APP_SSL_ENABLED='no' \
  XUVER_CERT_PATH='/etc/ssl/xuver.local.crt' \
  XUVER_CERT_KEY_PATH='/etc/ssl/xuver.local.key'

EXPOSE ${XUVER_APP_PORT}

COPY ./docker/Dockerfile /

COPY ./docker/healthcheck.sh /
HEALTHCHECK --interval=15s --timeout=15s --start-period=15s --retries=3 CMD [ "bash", "/healthcheck.sh" ]

COPY ./docker/entrypoint.sh /
CMD [ "bash", "/entrypoint.sh" ]

COPY docker/*.conf.template /etc/nginx/conf.d/

RUN mkdir -p /var/lib/xuver/downloads
VOLUME [ "/var/lib/xuver/downloads/" ]

COPY dist/ /usr/share/nginx/html/
COPY xversion.html /
COPY xversion.env /
