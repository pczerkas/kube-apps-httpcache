{{ define "configure_docker_service_proxy" }}
# defines docker registry proxy to be used by docker service
ARG DOCKER_REGISTRY_PROXY_HOST
ARG DOCKER_REGISTRY_PROXY_PORT
ARG NO_PROXY

RUN env

COPY debug/configure-docker-service-proxy.sh \
    /opt/bin/
RUN [ ! -z "$DOCKER_REGISTRY_PROXY_HOST" ] \
    && /opt/bin/configure-docker-service-proxy.sh \
    || [ -z "$DOCKER_REGISTRY_PROXY_HOST" ] && true
{{ end }}
