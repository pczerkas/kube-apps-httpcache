#!/bin/sh
set -e

mkdir -p /etc/systemd/system/containerd.service.d
cat <<EOF | tee /etc/systemd/system/containerd.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://$DOCKER_REGISTRY_PROXY_HOST:$DOCKER_REGISTRY_PROXY_PORT"
Environment="HTTPS_PROXY=http://$DOCKER_REGISTRY_PROXY_HOST:$DOCKER_REGISTRY_PROXY_PORT"
Environment="NO_PROXY=$NO_PROXY"
Environment="http_proxy=http://$DOCKER_REGISTRY_PROXY_HOST:$DOCKER_REGISTRY_PROXY_PORT"
Environment="https_proxy=http://$DOCKER_REGISTRY_PROXY_HOST:$DOCKER_REGISTRY_PROXY_PORT"
Environment="no_proxy=$NO_PROXY"
EOF
