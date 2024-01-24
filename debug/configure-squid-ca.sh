#!/bin/sh
set -e

# on alpine there is no apt-get
apt-get -y update || true
apt-get -y install ca-certificates || true

mkdir -p /etc/squid
cat /opt/ca/squid-ca.pem | tee /etc/squid/CA.pem
mkdir -p /usr/local/share/ca-certificates
cp /etc/squid/CA.pem /usr/local/share/ca-certificates/squid-CA.crt

update-ca-certificates
