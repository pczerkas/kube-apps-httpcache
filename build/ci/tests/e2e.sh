#!/bin/bash
set -e

echo 'Port-forwarding to kube-apps-httpcache service (http port)'
kubectl port-forward \
  service/kube-apps-httpcache \
  11000:80 \
  >/dev/null 2>&1 &

echo 'Port-forwarding to kube-apps-httpcache service (signaller port)'
kubectl port-forward \
  service/kube-apps-httpcache \
  11001:8090 \
  >/dev/null 2>&1 &

echo 'Port-forwarding to kube-apps-httpcache exporter container'
kubectl port-forward \
  deployment/kube-apps-httpcache \
  11010:9131 \
  >/dev/null 2>&1 &

echo 'Sleeping for 20 seconds'
sleep 20

echo 'Checking response from test-app1.com'
curl -v -H 'Host: test-app1.com' localhost:11000/test-req 2>&1 \
  | rg --passthru '"hostname":"test-app1\.com"'

echo 'Checking logs of varnishncsa'
kubectl logs deployment/kube-apps-httpcache -c varnishncsa \
  | rg --passthru '/test-req'

echo 'Checking response from exporter'
curl -v localhost:11010/metrics \
  | rg --passthru 'varnish_version\{major="7"'

echo 'Getting current goroutines num'
current_goroutines_num=$(
  curl -s localhost:11001/metrics \
    | rg 'go_goroutines [0-9]+' \
    | awk '{print $2}'
)
echo "Current goroutines num: $current_goroutines_num"

# update applications configmap
current_configmap=$(
  kubectl get configmap \
    "kube-apps-httpcache-applications" \
    -o json
)

echo 'Adding new (empty) application'
updated_applications=$(
  echo "$current_configmap" \
  | jq -r '.data."applications.json"' \
  | sed 's/]$/,{}]/'
)
updated_applications=$(
  echo "$updated_applications" \
  | sed 's/\\/\\\\/g' \
  | sed 's/"/\\"/g'
)
echo "${updated_applications}"
kubectl patch configmap \
  "kube-apps-httpcache-applications" \
  -p "{\"data\": { \"applications.json\": \"$updated_applications\" }}"

echo 'Sleeping for 20 seconds'
sleep 20

echo 'Getting new goroutines num'
new_goroutines_num=$(
  curl -s localhost:11001/metrics \
    | rg 'go_goroutines [0-9]+' \
    | awk '{print $2}'
)
echo "New goroutines num: $new_goroutines_num"

goroutines_num_diff=$(("$new_goroutines_num"-"$current_goroutines_num"))
goroutines_num_diff_abs=${goroutines_num_diff/#-}
echo "Goroutines num diff: $goroutines_num_diff_abs"
if [ "$goroutines_num_diff_abs" -gt "3" ]; then
  echo 'Goroutines num increased'
  exit 1
fi
