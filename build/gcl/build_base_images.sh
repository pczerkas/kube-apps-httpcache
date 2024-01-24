#!/bin/bash
set -e

build/gcl/build_gcl_base_image.sh
build/gcl/build_dind_image.sh
build/gcl/build_docker_git_image.sh

docker buildx prune
docker system prune
