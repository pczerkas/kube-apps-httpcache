#!/bin/bash
set -e

[ -f debug/system_wide_proxy.env ] && \
  source debug/system_wide_proxy.env

if [ -n "$SQUID_HOST" ]; then
  export http_proxy=http://$SQUID_HOST:$SQUID_HTTP_PORT
  export https_proxy=http://$SQUID_HOST:$SQUID_HTTPS_PORT
  export no_proxy="$NO_PROXY"
fi

PATH_FOR_GCL=$(pwd)/build/gcl/bin:$PATH

PATH=$PATH_FOR_GCL gitlab-ci-local \
    --shell-isolation \
    --privileged \
    --mount-cache \
    --variable SQUID_HOST=$SQUID_HOST \
    --variable SQUID_HTTP_PORT=$SQUID_HTTP_PORT \
    --variable SQUID_HTTPS_PORT=$SQUID_HTTPS_PORT \
    --variable DOCKER_REGISTRY_PROXY_HOST=$DOCKER_REGISTRY_PROXY_HOST \
    --variable DOCKER_REGISTRY_PROXY_PORT=$DOCKER_REGISTRY_PROXY_PORT \
    --variable NO_PROXY=$NO_PROXY \
    --variable CI_IMAGE_UBUNTU=local/gcl-ubuntu:latest \
    --variable CI_IMAGE_DIND=local/dind:latest \
    --variable CI_IMAGE_DOCKER_GIT=local/docker-git:latest \
    --variable CI_IMAGE_GITLAB_ACTIONS=local/gitlab-actions:latest \
    --variable CI_IMAGE_ACT_PLATFORM=local/act-ubuntu:latest \
    --variable CI_IMAGE_BUILDKIT=local/buildkit:latest \
    --variable MAIN_DOCKERFILE=build/package/docker/act/Dockerfile \
    --variable KIND_NODE_IMAGE=local/kind:latest \
    --volume /var/run/docker.sock:/var/run/docker-host.sock \
    --cleanup \
    "$@"
