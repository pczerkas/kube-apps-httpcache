#!/bin/bash
set -e

MIN_FREE_SPACE=2147483648

free_space=$(df -h / | tail -n 1 | awk '{print $4}' | numfmt --from=iec)
echo "Free space: $(echo $free_space | numfmt --to=iec)"

if [ "$free_space" -lt "$MIN_FREE_SPACE" ]; then
  echo "Free space is less than $(echo $MIN_FREE_SPACE | numfmt --to=iec), prunning docker"
  docker system prune --force
  docker buildx prune --force
fi
