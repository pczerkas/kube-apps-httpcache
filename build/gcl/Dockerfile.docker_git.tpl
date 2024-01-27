FROM docker:24.0.7-git

{{ template "configure_system_wide_proxy" }}
{{ template "configure_docker_registry_proxy" }}
