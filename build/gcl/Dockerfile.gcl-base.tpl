FROM ubuntu:latest

{{ template "configure_system_wide_proxy" }}
{{ template "configure_docker_registry_proxy" }}
