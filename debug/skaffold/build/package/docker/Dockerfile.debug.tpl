FROM local/build-kube-apps-httpcache-base:latest AS builder

ARG SKAFFOLD_GO_GCFLAGS
RUN echo "SKAFFOLD_GO_GCFLAGS: ${SKAFFOLD_GO_GCFLAGS}"

{{ template "configure_system_wide_proxy" }}

WORKDIR     /workspace
COPY        . .

RUN CGO_ENABLED=0 \
    go get \
        -ldflags "-s -w -extldflags '-static'" \
        github.com/go-delve/delve/cmd/dlv
RUN         CGO_ENABLED=0 GOOS=linux \
            go build \
                -gcflags="${SKAFFOLD_GO_GCFLAGS}" \
                -installsuffix cgo \
                -o kube-apps-httpcache \
                -a cmd/kube-apps-httpcache/main.go
RUN         cd exporter \
            && CGO_ENABLED=0 GOOS=linux \
                go build \
                    -gcflags="${SKAFFOLD_GO_GCFLAGS}" \
                    -installsuffix cgo \
                    -o prometheus_varnish_exporter

FROM        debian:bookworm-slim

{{ template "configure_system_wide_proxy" }}
{{ template "utilities_for_debugging" }}

LABEL       MAINTAINER="Przemek Czerkas <pczerkas@gmail.com>"

WORKDIR     /

RUN         apt-get -y update && apt-get upgrade && apt-get -y install curl && \
            curl -s https://packagecloud.io/install/repositories/varnishcache/varnish74/script.deb.sh | bash && \
            apt-get -y update && apt-get -y install varnish && \
            apt-get -y purge curl gnupg && \
            apt-get -y autoremove && apt-get -y autoclean && \
            rm -rf /var/cache/*

COPY --from=builder /go/bin/dlv dlv
COPY        --from=builder \
                /workspace/kube-apps-httpcache \
                /workspace/exporter/prometheus_varnish_exporter \
                /workspace/debug/skaffold/build/package/docker/entrypoint.sh \
                /

ENTRYPOINT [ "/entrypoint.sh" ]
