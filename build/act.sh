#!/bin/bash
set -e

[ -f debug/system_wide_proxy.env ] && \
  source debug/system_wide_proxy.env

if [ -n "$SQUID_HOST" ]; then
  export http_proxy=http://$SQUID_HOST:$SQUID_HTTP_PORT
  export https_proxy=http://$SQUID_HOST:$SQUID_HTTPS_PORT
  export no_proxy="$NO_PROXY"
fi

# templatize main Dockerfile
docker run \
  --rm \
  --user $(id -u):$(id -g) \
  -v "${PWD}:${PWD}" -w "${PWD}" \
  ghcr.io/bossm8/dockerfile-templater:debug \
    --verbose \
    --debug \
    --dockerfile.tpl build/package/docker/act/Dockerfile.tpl \
    --variants.def debug/variants.yml \
    --dockerfile.tpldir debug/includes \
    --out.dir build/package/docker/act \
    --out.fmt "Dockerfile"

# templatize goreleaser Dockerfile
docker run \
  --rm \
  --user $(id -u):$(id -g) \
  -v "${PWD}:${PWD}" -w "${PWD}" \
  ghcr.io/bossm8/dockerfile-templater:debug \
    --verbose \
    --debug \
    --dockerfile.tpl build/package/docker/act/GoReleaser.Dockerfile.tpl \
    --variants.def debug/variants.yml \
    --dockerfile.tpldir debug/includes \
    --out.dir build/package/docker/act \
    --out.fmt "GoReleaser.Dockerfile"

host_arch="$(uname -m)"
echo "host_arch: $host_arch"
case "$host_arch" in
  x86_64)
    matrix_os="ubuntu-latest"
    ;;
  aarch64)
    matrix_os="flyci-macos-large-latest-m2"
    ;;
  *)
    echo "Unsupported host architecture: $host_arch"
    exit 1
    ;;
esac

# act
act_default_args=(
  --platform ubuntu-latest=local/act-ubuntu:latest
  --env MAIN_DOCKERFILE=build/package/docker/act/Dockerfile
  --env KIND_NODE_IMAGE=local/kind:latest
  --container-options "-v act-toolcache:/opt/hostedtoolcache"
  --no-skip-checkout
  --pull=false
  --use-gitignore=false
  --rebuild=false
  --privileged
  --verbose
  --workflows .github/workflows/test_build.yml
  --matrix os:$matrix_os
  --rm
)
if [ -n "$DOCKER_REGISTRY_PROXY_HOST" ]; then
  act_default_args+=(
    --env DOCKER_REGISTRY_PROXY_HOST="$DOCKER_REGISTRY_PROXY_HOST"
    --env DOCKER_REGISTRY_PROXY_PORT="$DOCKER_REGISTRY_PROXY_PORT"
    --env NO_PROXY="$NO_PROXY"
    --env no_proxy="$NO_PROXY"
  )
fi
if [ -n "$SQUID_HOST" ]; then
  act_default_args+=(
    --env SQUID_HOST="$SQUID_HOST"
    --env SQUID_HTTP_PORT="$SQUID_HTTP_PORT"
    --env SQUID_HTTPS_PORT="$SQUID_HTTPS_PORT"
    --env NO_PROXY="$NO_PROXY"
    --env http_proxy="http://$SQUID_HOST:$SQUID_HTTP_PORT"
    --env https_proxy="http://$SQUID_HOST:$SQUID_HTTPS_PORT"
    --env no_proxy="$NO_PROXY"
  )
fi
act \
  "${act_default_args[@]}" \
  --job "$1"
