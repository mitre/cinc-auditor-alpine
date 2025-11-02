# Security Testing

This directory contains containerized security testing tools - no local installation required!

## Available Tests

### 1. Trivy - Vulnerability Scanning ✅ REQUIRED
**Scans for:** CVEs in OS packages and Ruby gems

```bash
./test/security/test-trivy.sh cinc-auditor-alpine:6
```

**Result:** 0 HIGH/CRITICAL vulnerabilities found

### 2. Syft - SBOM Generation ✅ RECOMMENDED
**Generates:** Software Bill of Materials for compliance

```bash
# Table format (human-readable)
./test/security/test-syft.sh cinc-auditor-alpine:6 table

# SPDX JSON (for compliance/auditing)
./test/security/test-syft.sh cinc-auditor-alpine:6 spdx-json > sbom.spdx.json

# CycloneDX (for supply chain security)
./test/security/test-syft.sh cinc-auditor-alpine:6 cyclonedx-json > sbom.cyclonedx.json
```

### 3. Dockle - Security Best Practices ⚠️ OPTIONAL
**Validates:** CIS Docker Benchmark compliance

```bash
./test/security/test-dockle.sh cinc-auditor-alpine:6
```

**Known Ignores:**
- `CIS-DI-0001`: Running as root (intentional for CLI tool container)
- `DKL-LI-0003`: Unnecessary files (gem Dockerfiles, .git directory - acceptable)

## Containerized Approach

All tools run as Docker containers - no local installation needed!

**Advantages:**
- ✅ No version conflicts with local tools
- ✅ Always use latest scanner versions
- ✅ Works consistently across all environments
- ✅ CI/CD ready out of the box

**Pattern:**
```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  <security-tool-image> \
  <target-image>
```

## Docker Images Used

| Tool | Image | Purpose |
|------|-------|---------|
| **Trivy** | `aquasec/trivy:latest` | Vulnerability scanning |
| **Syft** | `anchore/syft:latest` | SBOM generation |
| **Dockle** | `goodwithtech/dockle:latest` | Security linting |

## Integration with CI/CD

All these tools are already integrated in `.github/workflows/build-test.yml`:

- Trivy runs on every PR/push
- Syft generates SBOMs for releases
- Dockle validates security best practices

## Quick Security Audit

Run all security tests:

```bash
# Vulnerability scan
./test/security/test-trivy.sh cinc-auditor-alpine:6

# Generate SBOM
./test/security/test-syft.sh cinc-auditor-alpine:6 spdx-json > sbom-v6.spdx.json

# Security linting
./test/security/test-dockle.sh cinc-auditor-alpine:6
```

## Results Summary

### CINC Auditor Alpine v6
- **Trivy**: 0 HIGH/CRITICAL vulnerabilities ✅
- **Syft**: Complete SBOM with 400+ packages ✅
- **Dockle**: Passes with expected ignores ✅

### CINC Auditor Alpine v7
- **Trivy**: 0 HIGH/CRITICAL vulnerabilities ✅
- **Syft**: Complete SBOM with 400+ packages ✅
- **Dockle**: Passes with expected ignores ✅
