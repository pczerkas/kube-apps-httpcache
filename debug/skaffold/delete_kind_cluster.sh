#!/bin/bash
set -e

kind delete \
    cluster --name=kube-apps-httpcache
