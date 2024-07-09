FROM        golang:1.22.5 AS builder

WORKDIR     /workspace
COPY        . .
RUN         CGO_ENABLED=0 GOOS=linux \
            go build \
                -installsuffix cgo \
                -o kube-apps-httpcache \
                -a cmd/kube-apps-httpcache/main.go
RUN         cd exporter \
            && CGO_ENABLED=0 GOOS=linux \
                go build \
                    -installsuffix cgo \
                    -o prometheus_varnish_exporter

FROM        debian:bookworm-slim AS final

LABEL       MAINTAINER="Przemek Czerkas <pczerkas@gmail.com>"

WORKDIR     /

RUN         apt-get -qq update && apt-get -qq upgrade && apt-get -qq install curl && \
            curl -s https://packagecloud.io/install/repositories/varnishcache/varnish74/script.deb.sh | bash && \
            apt-get -qq update && apt-get -qq install varnish && \
            apt-get -qq purge curl gnupg && \
            apt-get -qq autoremove && apt-get -qq autoclean && \
            rm -rf /var/cache/*

COPY        --from=builder \
                /workspace/kube-apps-httpcache \
                /workspace/exporter/prometheus_varnish_exporter \
                /workspace/build/package/docker/entrypoint.sh \
                /

ENTRYPOINT  [ "/entrypoint.sh" ]
