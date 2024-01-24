{{ define "configure_system_wide_proxy" }}
# defines squid proxy to be used during build
ARG SQUID_HOST
ARG SQUID_HTTP_PORT
ARG SQUID_HTTPS_PORT
ARG NO_PROXY
ENV http_proxy=${SQUID_HOST:+http://$SQUID_HOST:$SQUID_HTTP_PORT}
ENV https_proxy=${SQUID_HOST:+http://$SQUID_HOST:$SQUID_HTTPS_PORT}
ENV no_proxy=${SQUID_HOST:+$NO_PROXY}

RUN env

# fixes "Hash Sum mismatch" error in apt
RUN [ ! -z "$SQUID_HOST" ] \
    && mkdir -p /etc/apt/apt.conf.d \
    && echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99fixbadproxy \
    && echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99fixbadproxy \
    && echo "Acquire::BrokenProxy true;" >> /etc/apt/apt.conf.d/99fixbadproxy \
    && echo "Acquire::Check-Valid-Until false;" >> /etc/apt/apt.conf.d/99fixbadproxy \
    && echo "Acquire::Check-Date false;" >> /etc/apt/apt.conf.d/99fixbadproxy \
    || [ -z "$SQUID_HOST" ] && true

# configure system-wide proxy
COPY debug/configure-squid-ca.sh \
    /opt/bin/
RUN --mount=target=/mnt,source=debug/ca/ \
    [ -f /mnt/squid-ca.pem ] \
    && mkdir -p /opt/ca/ \
    && cp /mnt/squid-ca.pem /opt/ca/ || true
RUN [ ! -z "$SQUID_HOST" ] \
    && /opt/bin/configure-squid-ca.sh \
    && echo "export http_proxy=http://$SQUID_HOST:$SQUID_HTTP_PORT" >> /etc/profile \
    && echo "export https_proxy=http://$SQUID_HOST:$SQUID_HTTPS_PORT" >> /etc/profile \
    && echo "export no_proxy='$NO_PROXY'" >> /etc/profile \
    && mkdir -p /etc/apt/apt.conf.d \
    && echo "Acquire::http::Proxy \"http://$SQUID_HOST:$SQUID_HTTP_PORT\";" > /etc/apt/apt.conf.d/00proxy \
    && echo "Acquire::https::Proxy \"http://$SQUID_HOST:$SQUID_HTTPS_PORT\";" >> /etc/apt/apt.conf.d/00proxy \
    || [ -z "$SQUID_HOST" ] && true
{{ end }}
