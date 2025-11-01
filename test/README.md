# Testing Strategy

This project uses multiple complementary testing approaches to ensure container quality and functionality.

## Testing Layers

### 1. Dockerfile Linting - Hadolint ✅
**What it validates:** Dockerfile best practices, security issues, build optimization

```bash
hadolint Dockerfile
```

### 2. Container Structure Tests - Google's container-structure-test ✅
**What it validates:** Image structure, commands, files, metadata

```bash
container-structure-test test --image cinc-auditor-alpine:6 --config container-structure-test.yaml
```

### 3. Functional Tests - InSpec Profile ✅ PRIMARY
**What it validates:** Actual runtime behavior, component functionality

The container tests itself using CINC Auditor - no external installation needed!

```bash
# Test v6 with input file
docker run --rm -v $(pwd)/test:/test cinc-auditor-alpine:6 \
  cinc-auditor exec /test/integration --input-file=/test/integration/inputs-v6.yml

# Test v7 with input file
docker run --rm -v $(pwd)/test:/test cinc-auditor-alpine:7 \
  cinc-auditor exec /test/integration --input-file=/test/integration/inputs-v7.yml
```

**InSpec Controls:**
- `cinc-auditor-installation` - CINC Auditor binary and version
- `train-k8s-container-plugin` - Plugin installation and version
- `kubectl-installation` - kubectl functionality
- `ruby-version` - Ruby 3.4+ installed
- `required-directories` - Essential directories present
- `git-workspace-initialized` - Git repo in workspace
- `inspec-execution-test` - Actual InSpec test execution
- `environment-variables` - Required env vars set

### 4. Alternative: Goss Tests (BONUS DEMO)
**What it validates:** Fast, Docker-native functional testing

No local goss installation needed - uses containerized approach!

```bash
# Test v6
./test/goss/test-with-goss.sh cinc-auditor-alpine:6 goss-vars-v6.yaml

# Test v7
./test/goss/test-with-goss.sh cinc-auditor-alpine:7 goss-vars-v7.yaml
```

See `test/goss/README.md` for more details.

## Complete Test Suite

### Automated (Recommended)
```bash
# Update scripts/test-all.sh to run proper tests
# Coming soon
```

### Manual Testing
```bash
# 1. Hadolint
hadolint Dockerfile

# 2. Container Structure Tests
container-structure-test test --image cinc-auditor-alpine:6 --config container-structure-test.yaml

# 3. InSpec Tests (Primary)
docker run --rm -v $(pwd)/test:/test cinc-auditor-alpine:6 \
  cinc-auditor exec /test/integration --input-file=/test/integration/inputs-v6.yml

# 4. Goss Tests (Bonus)
./test/goss/test-with-goss.sh cinc-auditor-alpine:6 goss-vars-v6.yaml
```

## Future Additions

### Security Scanning - Trivy
```bash
trivy image --severity HIGH,CRITICAL cinc-auditor-alpine:6
```

### SBOM Generation - Syft
```bash
syft cinc-auditor-alpine:6 -o spdx-json > sbom.spdx.json
```

### Security Best Practices - Dockle
```bash
dockle cinc-auditor-alpine:6
```

## Why Multiple Testing Tools?

Each tool serves a specific purpose:

| Tool | Purpose | Speed | Coverage |
|------|---------|-------|----------|
| **Hadolint** | Dockerfile quality | Instant | Build-time |
| **container-structure-test** | Image structure | Fast | Post-build |
| **InSpec** | Functional behavior | Medium | Runtime |
| **Goss/dgoss** | Docker-native functional | Very Fast | Runtime |
| **Trivy** | Security vulnerabilities | Medium | Security |

This layered approach ensures comprehensive validation from build-time through runtime.
