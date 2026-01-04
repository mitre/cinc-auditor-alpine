# Quick Start Guide

## Prerequisites
- Docker Desktop 4.x+ (includes buildx)
- OR Docker with buildx plugin

## Build Images

```bash
# Build both v6 and v7 for your platform
docker buildx bake

# Build specific version
docker buildx bake v6     # CINC 6.8.24 stable
docker buildx bake v7     # CINC 7 stable
```

## Test

```bash
# Quick smoke test
docker run --rm cinc-auditor-alpine:6 cinc-auditor version
docker run --rm cinc-auditor-alpine:6 cinc-auditor plugin list

# Run full InSpec test suite (container tests itself!)
docker run --rm -v $(pwd)/test:/test cinc-auditor-alpine:6 \
  cinc-auditor exec /test/integration --input-file=/test/integration/inputs-v6.yml
```

## Use with Kubernetes

```bash
# Scan a Kubernetes container
docker run --rm \
  -v ~/.kube/config:/root/.kube/config:ro \
  cinc-auditor-alpine:latest \
  cinc-auditor detect -t k8s-container://default/nginx-pod/nginx
```

## Next Steps

- See [DOCKER-BAKE.md](DOCKER-BAKE.md) for advanced build options
- See [README.md](README.md) for full documentation
- See [examples/k8s-scan.sh](examples/k8s-scan.sh) for Kubernetes scanning examples
