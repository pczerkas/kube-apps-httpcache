FROM docker:24.0.7-git@sha256:b8a80830eafd07b770b56156e7b03cda679f836692ed46c73d3ee91dd3c6fa7c

{{ template "configure_system_wide_proxy" }}
{{ template "configure_docker_registry_proxy" }}
