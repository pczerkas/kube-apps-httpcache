#!/bin/bash
set -e

current_config=$(kubectl get configmap "kube-apps-httpcache-applications" -o json)
updated_applications=$(echo "$current_config" | jq -r '.data."applications.json"' | sed 's/]$/,{}]/')
updated_applications=$(echo "$updated_applications" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
echo "${updated_applications}"
kubectl patch configmap "kube-apps-httpcache-applications" -p "{\"data\": { \"applications.json\": \"$updated_applications\" }}"
