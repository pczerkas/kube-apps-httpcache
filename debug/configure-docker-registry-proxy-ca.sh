#!/bin/sh
set -e

# on alpine there is no apt-get
apt-get -y update || true
apt-get -y install ca-certificates || true

mkdir -p /etc/docker-registry-proxy
cat /opt/ca/docker-registry-proxy-ca.crt | tee /etc/docker-registry-proxy/CA.crt
mkdir -p /usr/local/share/ca-certificates
cp /etc/docker-registry-proxy/CA.crt /usr/local/share/ca-certificates/docker-registry-proxy-CA.crt

update-ca-certificates
