{{ define "utilities_for_debugging" }}
# utilities for debugging
RUN apt-get -y update \
    && apt-get -y install \
        procps \
        net-tools \
        dnsutils \
        iputils-ping \
        htop \
        mc \
    # cleanup
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
    && apt-get -qyy clean
{{ end }}
