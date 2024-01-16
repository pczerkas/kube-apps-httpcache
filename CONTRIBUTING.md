# Contribution guide

## Deployment on a local cluster

This guide explains how to build the kube-apps-httpcache Docker image locally and test it in a local KinD[^1] cluster.

1. Build image and load into kind:

    ```bash
    $ docker build -t ghcr.io/pczerkas/kube-apps-httpcache:dev -f build/packages/docker/Dockerfile .
    $ kind load docker-image ghcr.io/pczerkas/kube-apps-httpcache:dev
    ```

2. Deploy an example backend workload:

    ```bash
    $ kubectl apply -f examples/test-backend.yaml
    ```

3. Deploy Helm chart with example configuration:

    ```bash
    $ helm upgrade --install -f ./test/test-values.yaml kube-apps-httpcache ./chart
    ```

4. Port-forward to the cache:

    ```bash
    $ kubectl port-forward svc/kube-apps-httpcache 8080:80
    ```

[^1]: <https://kind.sigs.k8s.io>
