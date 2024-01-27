ARG ARCH=
FROM        ${ARCH}debian:bookworm-slim

ARG CACHEBUST

LABEL       MAINTAINER="Przemek Czerkas <pczerkas@gmail.com>"

WORKDIR     /

RUN         apt-get -qq update && apt-get -qq upgrade && apt-get -qq install curl && \
            curl -s https://packagecloud.io/install/repositories/varnishcache/varnish74/script.deb.sh | bash && \
            apt-get -qq update && apt-get -qq install varnish && \
            apt-get -qq purge curl gnupg && \
            apt-get -qq autoremove && apt-get -qq autoclean && \
            rm -rf /var/cache/*

COPY        kube-apps-httpcache \
            prometheus_varnish_exporter \
            build/package/docker/entrypoint.sh \
            /

ENTRYPOINT  [ "/entrypoint.sh" ]
