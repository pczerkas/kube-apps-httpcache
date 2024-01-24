#!/bin/bash
set -e

# templatize
docker run \
    --rm \
    --user $(id -u):$(id -g) \
    -v "${PWD}/../:${PWD}/../" -w "${PWD}/../" \
    ghcr.io/bossm8/dockerfile-templater:debug \
        --verbose \
        --debug \
        --dockerfile.tpl skaffold/build/package/docker/Dockerfile.base.tpl \
        --variants.def variants.yml \
        --dockerfile.tpldir includes \
        --out.dir skaffold/build/package/docker \
        --out.fmt "Dockerfile.base"

# templatize
docker run \
    --rm \
    --user $(id -u):$(id -g) \
    -v "${PWD}/../:${PWD}/../" -w "${PWD}/../" \
    ghcr.io/bossm8/dockerfile-templater:debug \
        --verbose \
        --debug \
        --dockerfile.tpl skaffold/build/package/docker/Dockerfile.debug.tpl \
        --variants.def variants.yml \
        --dockerfile.tpldir includes \
        --out.dir skaffold/build/package/docker \
        --out.fmt "Dockerfile.debug"

# templatize
docker run \
  --rm \
  --user $(id -u):$(id -g) \
  -v "${PWD}/../:${PWD}/../" -w "${PWD}/../" \
  ghcr.io/bossm8/dockerfile-templater:debug \
    --verbose \
    --debug \
    --dockerfile.tpl skaffold/build/package/docker/Dockerfile.kind-base.tpl \
    --variants.def variants.yml \
    --dockerfile.tpldir includes \
    --out.dir skaffold/build/package/docker \
    --out.fmt "Dockerfile.kind-base"
