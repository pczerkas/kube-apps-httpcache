{{ define "configure_docker_registry_proxy" }}
# defines docker registry proxy to be used during build
ARG DOCKER_REGISTRY_PROXY_HOST
ARG NO_PROXY
ENV no_proxy=${DOCKER_REGISTRY_PROXY_HOST:+$NO_PROXY}

RUN env

# configure docker registry proxy
COPY debug/configure-docker-registry-proxy-ca.sh \
    /opt/bin/
RUN --mount=target=/mnt,source=debug/ca/ \
    [ -f /mnt/docker-registry-proxy-ca.crt ] \
    && mkdir -p /opt/ca/ \
    && cp /mnt/docker-registry-proxy-ca.crt /opt/ca/ || true
RUN [ ! -z "$DOCKER_REGISTRY_PROXY_HOST" ] \
    && /opt/bin/configure-docker-registry-proxy-ca.sh \
    && echo "export no_proxy='$NO_PROXY'" >> /etc/profile \
    || [ -z "$DOCKER_REGISTRY_PROXY_HOST" ] && true
{{ end }}
