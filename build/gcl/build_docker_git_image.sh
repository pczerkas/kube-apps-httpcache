#!/bin/bash
set -e

[ -f debug/system_wide_proxy.env ] && \
  source debug/system_wide_proxy.env

if [ -n "$SQUID_HOST" ]; then
  export http_proxy=http://$SQUID_HOST:$SQUID_HTTP_PORT
  export https_proxy=http://$SQUID_HOST:$SQUID_HTTPS_PORT
  export no_proxy="$NO_PROXY"
fi

BUILDER_NAME=docker-git-builder
IMAGE_TAG=local/docker-git:latest

# shellcheck disable=SC2001
on_exit_func () {
  local next="$1"
  eval "on_exit () {
    local oldcmd='$(echo "$next" | sed -e s/\'/\'\\\\\'\'/g)'
    local newcmd=\"\$oldcmd; \$1\"
    trap -- \"\$newcmd\" EXIT
    on_exit_func \"\$newcmd\"
  }"
}
on_exit_func true

function remove_builder {
  DOCKER_BUILDKIT=1 \
    docker buildx rm $BUILDER_NAME
}

# templatize
docker run \
  --rm \
  --user $(id -u):$(id -g) \
  -v "${PWD}:${PWD}" -w "${PWD}" \
  ghcr.io/bossm8/dockerfile-templater:debug \
    --verbose \
    --debug \
    --dockerfile.tpl build/gcl/Dockerfile.docker_git.tpl \
    --variants.def debug/variants.yml \
    --dockerfile.tpldir debug/includes \
    --out.dir build/gcl \
    --out.fmt "Dockerfile.docker_git"

# create builder and set max log size to unlimited
docker_buildx_create_default_args=(
  --name "$BUILDER_NAME"
  --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=-1
  --buildkitd-flags '--allow-insecure-entitlement network.host'
  --use
)
if [ -n "$DOCKER_REGISTRY_PROXY_HOST" ]; then
  # shellcheck disable=SC2206
  docker_buildx_create_default_args+=(
    --driver-opt env.http_proxy="$DOCKER_REGISTRY_PROXY_HOST:$DOCKER_REGISTRY_PROXY_PORT"
    --driver-opt env.https_proxy="$DOCKER_REGISTRY_PROXY_HOST:$DOCKER_REGISTRY_PROXY_PORT"
    --driver-opt '"env.no_proxy='$NO_PROXY'"'
  )
fi
DOCKER_BUILDKIT=1 \
  docker buildx create \
    "${docker_buildx_create_default_args[@]}" \
    --config /etc/buildkit/buildkitd.toml \
  && on_exit remove_builder

# build
docker_buildx_build_default_args=(
  --progress plain
  -f build/gcl/Dockerfile.docker_git
  --tag "$IMAGE_TAG"
  --provenance false
  --load
)
if [ -n "$DOCKER_REGISTRY_PROXY_HOST" ]; then
  docker_buildx_build_default_args+=(
    --build-arg DOCKER_REGISTRY_PROXY_HOST="$DOCKER_REGISTRY_PROXY_HOST"
    --build-arg DOCKER_REGISTRY_PROXY_PORT="$DOCKER_REGISTRY_PROXY_PORT"
    --build-arg NO_PROXY="$NO_PROXY"
  )
fi
if [ -n "$SQUID_HOST" ]; then
  docker_buildx_build_default_args+=(
    --build-arg SQUID_HOST="$SQUID_HOST"
    --build-arg SQUID_HTTP_PORT="$SQUID_HTTP_PORT"
    --build-arg SQUID_HTTPS_PORT="$SQUID_HTTPS_PORT"
    --build-arg NO_PROXY="$NO_PROXY"
  )
fi
DOCKER_BUILDKIT=1 \
  docker buildx build \
    "${docker_buildx_build_default_args[@]}" \
    .
