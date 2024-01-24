#!/bin/bash
set -e

build/act/build_act_base_image.sh
build/act/build_buildkit_base_image.sh
build/act/build_kind_base_image.sh

docker buildx prune
docker system prune
