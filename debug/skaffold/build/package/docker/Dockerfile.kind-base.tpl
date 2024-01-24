ARG KIND_NODE_IMAGE
FROM ${KIND_NODE_IMAGE}

{{ template "configure_system_wide_proxy" }}
{{ template "configure_docker_registry_proxy" }}
{{ template "configure_containerd_service_proxy" }}

{{ template "utilities_for_debugging" }}
