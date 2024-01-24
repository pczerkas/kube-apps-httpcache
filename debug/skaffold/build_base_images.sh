#!/bin/bash
set -e

pushd debug/skaffold
./prepare_dockerfiles.sh
./build_base_image.sh
./build_kind_base_image.sh
popd

docker buildx prune
docker system prune
