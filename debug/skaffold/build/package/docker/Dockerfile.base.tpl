FROM        golang:1.21@sha256:04cf306d01a03309934b49ac4b9f487abb8a054b71141fa53df6df482ab7d7eb

{{ template "configure_system_wide_proxy" }}

WORKDIR /workspace

RUN cd / \
     && CGO_ENABLED=0 \
          go install \
               github.com/go-delve/delve/cmd/dlv@latest
