FROM catthehacker/ubuntu:act-latest@sha256:91af2c9a8e7bcd60f8727b8e9edd5676e3ab0499e2675c16e0cd453a7911a36b

{{ template "configure_system_wide_proxy" }}
# needed by nodejs
ENV NODE_EXTRA_CA_CERTS="/etc/squid/CA.pem"

{{ template "configure_docker_registry_proxy" }}
