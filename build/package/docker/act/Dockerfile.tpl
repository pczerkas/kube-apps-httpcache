FROM        golang:1.22.5 AS builder

{{ template "configure_system_wide_proxy" }}

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

COPY        --from=builder \
                /workspace/kube-apps-httpcache \
                /workspace/exporter/prometheus_varnish_exporter \
                /workspace/build/package/docker/act/entrypoint.sh \
                /

ENTRYPOINT  [ "/entrypoint.sh" ]
