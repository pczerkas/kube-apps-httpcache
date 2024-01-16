#!/bin/bash
set -e

# have to unset proxy envs for kube-apps-httpcache
env \
    --unset=http_proxy \
    --unset=https_proxy \
    /kube-apps-httpcache "$@"
