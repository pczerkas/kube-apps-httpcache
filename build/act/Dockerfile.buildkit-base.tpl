FROM moby/buildkit:v0.12.4

{{ template "configure_system_wide_proxy" }}
{{ template "configure_docker_registry_proxy" }}
