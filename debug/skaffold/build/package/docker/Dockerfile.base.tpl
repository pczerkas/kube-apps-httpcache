FROM        golang:1.21

{{ template "configure_system_wide_proxy" }}

WORKDIR /workspace

RUN cd / \
     && CGO_ENABLED=0 \
          go install \
               github.com/go-delve/delve/cmd/dlv@latest
