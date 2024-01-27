ARG ARCH=
FROM        ${ARCH}debian:bookworm-slim

ARG CACHEBUST
{{ template "configure_system_wide_proxy" }}
{{ template "utilities_for_debugging" }}

LABEL       MAINTAINER="Przemek Czerkas <pczerkas@gmail.com>"

WORKDIR     /

RUN         apt-get -y update && apt-get -y upgrade && apt-get -y install curl && \
            curl -s https://packagecloud.io/install/repositories/varnishcache/varnish74/script.deb.sh | bash && \
            apt-get -y update && apt-get -y install varnish && \
            apt-get -y purge curl gnupg && \
            apt-get -y autoremove && apt-get -y autoclean && \
            rm -rf /var/cache/*

COPY        kube-apps-httpcache \
            prometheus_varnish_exporter \
            build/package/docker/act/entrypoint.sh \
            /

ENTRYPOINT  [ "/entrypoint.sh" ]
