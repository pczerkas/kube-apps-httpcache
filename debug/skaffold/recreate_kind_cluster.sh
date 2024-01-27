#!/bin/bash
set -e

kind delete \
    cluster --name=kube-apps-httpcache
kind create \
    cluster \
        --name=kube-apps-httpcache \
        --config=kind-config.yaml \
        --image=local/skaffold-kind:latest
