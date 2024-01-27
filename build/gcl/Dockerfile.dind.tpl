FROM docker:24.0.7-dind

{{ template "configure_system_wide_proxy" }}
{{ template "configure_docker_registry_proxy" }}

RUN mkdir -p /etc/docker \
    && cat <<EOF | tee /etc/docker/daemon.json
{
  "experimental": true
}
EOF

# not working in docker:dind
# RUN mkdir -p /etc/docker \
#     && cat <<EOF | tee /etc/docker/daemon.json
# {
#   "proxies": {
#     "http-proxy": "http://$DOCKER_REGISTRY_PROXY_HOST:$DOCKER_REGISTRY_PROXY_PORT",
#     "https-proxy": "http://$DOCKER_REGISTRY_PROXY_HOST:$DOCKER_REGISTRY_PROXY_PORT",
#     "no-proxy": "$NO_PROXY"
#   }
# }
# EOF

# maybe working in docker:dind
{{ template "configure_docker_service_proxy" }}

# maybe working in docker:dind
{{ template "configure_containerd_service_proxy" }}
