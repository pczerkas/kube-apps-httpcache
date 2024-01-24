#!/bin/bash
set  -e

# have to unset proxy envs for kube-apps-httpcache
exec env \
    --unset=http_proxy \
    --unset=https_proxy \
    /dlv \
        --listen=:56268 \
        --headless=true \
        --api-version=2 \
        --accept-multiclient \
        exec /kube-apps-httpcache -- "$@"
