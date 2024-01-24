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

FROM        debian:bookworm-slim@sha256:d6a343a9b7faf367bd975cadb5c9af51874a8ecf1a2b2baa96877d578ac96722 AS final

{{ template "configure_system_wide_proxy" }}
{{ template "utilities_for_debugging" }}

ENV         EXPORTER_VERSION=1.6.1
LABEL       MAINTAINER="Przemek Czerkas <pczerkas@gmail.com>"

WORKDIR     /

RUN         apt-get -y update && apt-get upgrade && apt-get -y install curl && \
            curl -s https://packagecloud.io/install/repositories/varnishcache/varnish74/script.deb.sh | bash && \
            apt-get -y update && apt-get -y install varnish && \
            apt-get -y purge curl gnupg && \
            apt-get -y autoremove && apt-get -y autoclean && \
            rm -rf /var/cache/*

RUN         mkdir /exporter && chown varnish /exporter

ADD         --chown=varnish https://github.com/jonnenauha/prometheus_varnish_exporter/releases/download/${EXPORTER_VERSION}/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz /tmp

RUN         cd /exporter && \
            tar -xzf /tmp/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz && \
            ln -sf /exporter/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-amd64/prometheus_varnish_exporter prometheus_varnish_exporter

COPY --from=builder /go/bin/dlv dlv
COPY        --from=builder \
                /workspace/kube-apps-httpcache \
                /workspace/debug/skaffold/build/package/docker/entrypoint.sh \
                /

ENTRYPOINT [ "/entrypoint.sh" ]
