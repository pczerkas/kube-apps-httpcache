FROM moby/buildkit:master@sha256:fd17acb9fd5b321401af2187b64c098cb28c2f7ce1749c8540f5f01ff5b32124

{{ template "configure_system_wide_proxy" }}
{{ template "configure_docker_registry_proxy" }}
