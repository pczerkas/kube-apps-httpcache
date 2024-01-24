{{ define "configure_containerd_service_proxy" }}
# defines docker registry proxy to be used by containerd
ARG DOCKER_REGISTRY_PROXY_HOST
ARG DOCKER_REGISTRY_PROXY_PORT
ARG NO_PROXY

RUN env

COPY debug/configure-containerd-service-proxy.sh \
    /opt/bin/
RUN [ ! -z "$DOCKER_REGISTRY_PROXY_HOST" ] \
    && /opt/bin/configure-containerd-service-proxy.sh \
    || [ -z "$DOCKER_REGISTRY_PROXY_HOST" ] && true
{{ end }}
