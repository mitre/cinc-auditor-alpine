# Testing Guide

Comprehensive testing documentation for the CINC Auditor Alpine Docker image.

## Test Suites

### 1. Basic Functionality Tests (`tests/01-basic.sh`)

Tests core CINC Auditor functionality:
- ✅ Image builds successfully
- ✅ CINC Auditor is installed and executable
- ✅ Version information is correct
- ✅ Ruby environment is working
- ✅ Non-root user execution
- ✅ Health check passes

**Run:**
```bash
./scripts/test.sh basic
```

### 2. Plugin Tests (`tests/02-plugin.sh`)

Tests train-k8s-container plugin installation:
- ✅ Plugin is installed
- ✅ Plugin is listed in `cinc-auditor plugin list`
- ✅ Plugin version matches v2.0
- ✅ Plugin can be loaded

**Run:**
```bash
./scripts/test.sh plugin
```

### 3. Kubernetes Integration Tests (`tests/03-kubernetes.sh`)

Tests kubectl and K8s connectivity:
- ✅ kubectl is installed
- ✅ kubectl version is correct
- ✅ kubectl can connect (if kubeconfig provided)
- ✅ train-k8s-container can detect K8s containers

**Run:**
```bash
# Without K8s cluster (basic checks only)
./scripts/test.sh kubernetes

# With K8s cluster (full integration)
./scripts/test.sh kubernetes --with-cluster
```

### 4. Certificate Tests (`tests/04-certificates.sh`)

Tests custom certificate handling:
- ✅ Custom certs are copied
- ✅ CA certificates are updated
- ✅ HTTPS connections work with corporate certs

**Run:**
```bash
./scripts/test.sh certificates
```

## Running All Tests

```bash
# Run all tests
./scripts/test.sh

# Run with verbose output
./scripts/test.sh --verbose

# Run with cleanup on failure
./scripts/test.sh --cleanup
```

## Manual Testing

### Test CINC Auditor

```bash
# Check version
docker run --rm cinc-auditor-alpine:latest cinc-auditor version

# Interactive shell
docker run -it --rm cinc-auditor-alpine:latest cinc-auditor shell
```

### Test train-k8s-container Plugin

```bash
# List plugins
docker run --rm cinc-auditor-alpine:latest cinc-auditor plugin list

# Test K8s connection (requires kubeconfig)
docker run -it --rm \
  -v ~/.kube/config:/home/auditor/.kube/config:ro \
  cinc-auditor-alpine:latest \
  cinc-auditor detect -t k8s-container://default/test-pod/test-container
```

### Test kubectl

```bash
# Check kubectl version
docker run --rm cinc-auditor-alpine:latest kubectl version --client

# List pods (requires kubeconfig)
docker run --rm \
  -v ~/.kube/config:/home/auditor/.kube/config:ro \
  cinc-auditor-alpine:latest \
  kubectl get pods --all-namespaces
```

## Integration Testing with kind

For full end-to-end testing, use kind (Kubernetes in Docker):

```bash
# Create kind cluster
kind create cluster --name test-cluster

# Deploy test pod
kubectl run test-pod --image=alpine:3.19 --command -- sleep infinity

# Wait for pod to be ready
kubectl wait --for=condition=Ready pod/test-pod --timeout=60s

# Test with CINC Auditor
docker run -it --rm \
  --network host \
  -v ~/.kube/config:/home/auditor/.kube/config:ro \
  cinc-auditor-alpine:latest \
  cinc-auditor detect -t k8s-container:///test-pod/test-pod

# Cleanup
kind delete cluster --name test-cluster
```

## CI/CD Testing

Example GitHub Actions workflow:

```yaml
name: Test Docker Image

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: ./scripts/build.sh

      - name: Run tests
        run: ./scripts/test.sh

      - name: Setup kind
        uses: helm/kind-action@v1

      - name: Run K8s integration tests
        run: ./scripts/test.sh kubernetes --with-cluster
```

## Troubleshooting

### Plugin Not Installing

**Symptom:** `cinc-auditor plugin install` fails

**Solutions:**
1. Check Ruby version: `docker run --rm cinc-auditor-alpine:latest ruby --version` (should be 3.1+)
2. Check build logs for gem compilation errors
3. Verify train-k8s-container gem was built: `ls -la /tmp/plugin/train-k8s-container/*.gem`

### kubectl Connection Issues

**Symptom:** `kubectl get pods` fails

**Solutions:**
1. Verify kubeconfig is mounted: `-v ~/.kube/config:/home/auditor/.kube/config:ro`
2. Check file permissions: `ls -la ~/.kube/config`
3. For kind clusters, use `--network host` flag
4. Verify KUBECONFIG env var: `docker run --rm -v ~/.kube/config:/home/auditor/.kube/config:ro cinc-auditor-alpine:latest env | grep KUBE`

### Certificate Issues

**Symptom:** HTTPS connections fail with certificate errors

**Solutions:**
1. Verify certs are in `certs/` directory before build
2. Check certificate format: `openssl x509 -in certs/corp.crt -text -noout`
3. Rebuild with `--with-certs` flag
4. Verify certs in image: `docker run --rm cinc-auditor-alpine:latest ls -la /usr/local/share/ca-certificates/corp/`

### Image Size Too Large

**Symptom:** Image exceeds 500MB

**Solutions:**
1. Check build cache: `docker system df`
2. Rebuild without cache: `docker build --no-cache`
3. Verify multi-stage build is working (check layers)
4. Remove unnecessary files in build stage

## Test Results Format

Tests output results in this format:

```
✅ PASS: CINC Auditor version check
✅ PASS: Plugin installation
✅ PASS: kubectl version
❌ FAIL: K8s connection (kubeconfig not provided)
⚠️  SKIP: Certificate tests (no certs provided)

Summary: 3 passed, 1 failed, 1 skipped
```

## Expected Test Duration

- Basic tests: ~30 seconds
- Plugin tests: ~45 seconds
- Kubernetes tests (without cluster): ~30 seconds
- Kubernetes tests (with cluster): ~3-5 minutes
- Full test suite: ~5-10 minutes with kind
