ARG ARCH=
FROM        ${ARCH}debian:bookworm-slim

ARG CACHEBUST
{{ template "configure_system_wide_proxy" }}

ENV         EXPORTER_VERSION=1.6.1
LABEL       MAINTAINER="Przemek Czerkas <pczerkas@gmail.com>"

WORKDIR     /

RUN         apt-get -y update && apt-get -y upgrade && apt-get -y install curl && \
            curl -s https://packagecloud.io/install/repositories/varnishcache/varnish74/script.deb.sh | bash && \
            apt-get -y update && apt-get -y install varnish && \
            apt-get -y purge curl gnupg && \
            apt-get -y autoremove && apt-get -y autoclean && \
            rm -rf /var/cache/*

RUN         mkdir /exporter \
            && chown varnish /exporter

ADD         --chown=varnish https://github.com/jonnenauha/prometheus_varnish_exporter/releases/download/${EXPORTER_VERSION}/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz /tmp

RUN         cd /exporter && \
            tar -xzf /tmp/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz && \
            ln -sf /exporter/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-amd64/prometheus_varnish_exporter prometheus_varnish_exporter

COPY        kube-apps-httpcache \
            build/package/docker/act/entrypoint.sh \
            /

ENTRYPOINT  [ "/entrypoint.sh" ]
