# SSL Verification Configuration

This document details how SSL verification is disabled when using the `--ssl-no-verify` build flag. Each tool requires different configuration.

## When to Use `--ssl-no-verify`

⚠️ **Security Warning**: Disabling SSL verification should ONLY be used in controlled corporate environments with:
- SSL inspection/MITM proxies
- Internal certificate authorities not in standard trust stores
- Development/testing environments

**Never** disable SSL verification in production without proper corporate certificates installed.

## Tools and Their SSL Verification Flags

### 1. Git (`git clone`)

**Standard Git Config:**
```bash
git config --global http.sslVerify false
```

**What we do in Dockerfile:**
```dockerfile
if [ "$SSL_NO_VERIFY" = "true" ]; then
    git config --global http.sslVerify false
fi
```

**Alternative (environment variable):**
```bash
GIT_SSL_NO_VERIFY=true git clone https://...
```

### 2. cURL (`curl` for downloading kubectl, etc.)

**Flag:**
```bash
curl -k https://...
# or
curl --insecure https://...
```

**What we do in Dockerfile:**
```dockerfile
if [ "$SSL_NO_VERIFY" = "true" ]; then
    curl -k -LO "https://dl.k8s.io/..."
else
    curl -LO "https://dl.k8s.io/..."
fi
```

### 3. Ruby Bundler / RubyGems

**Bundler Config:**
```bash
bundle config set --global ssl_verify_mode 0
```

**Gem Sources (force re-add to bypass cache):**
```bash
gem sources --remove https://rubygems.org/
gem sources --add https://rubygems.org/
gem sources --remove https://rubygems.cinc.sh/
gem sources --add https://rubygems.cinc.sh/
```

**What we do in Dockerfile:**
```dockerfile
if [ "$SSL_NO_VERIFY" = "true" ]; then
    bundle config set --global ssl_verify_mode 0
    gem sources --add https://rubygems.org/ --remove https://rubygems.org/
    gem sources --add https://rubygems.cinc.sh/ --remove https://rubygems.cinc.sh/
fi
bundle install --system
```

**Environment Variables (alternative):**
```bash
export SSL_CERT_FILE=/dev/null
export BUNDLE_SSL_VERIFY_MODE=0
```

### 4. kubectl (Runtime - NOT build time)

kubectl SSL verification is controlled at **runtime**, not during build.

**kubeconfig setting:**
```yaml
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://kubernetes.example.com
  name: my-cluster
```

**Command-line flag:**
```bash
kubectl --insecure-skip-tls-verify get pods
```

**What you need to do:**
- Add `insecure-skip-tls-verify: true` to your kubeconfig
- OR use `--insecure-skip-tls-verify` flag when running kubectl

### 5. Docker Build (NOT implemented)

Docker build itself can have SSL issues when pulling base images.

**Docker daemon config (`/etc/docker/daemon.json`):**
```json
{
  "insecure-registries": ["registry.example.com:5000"]
}
```

**Build arg approach:**
```dockerfile
ARG CERT_PATH=/etc/ssl/certs/ca-certificates.crt
ENV REQUESTS_CA_BUNDLE=$CERT_PATH
ENV SSL_CERT_FILE=$CERT_PATH
```

## Current Implementation Summary

### What `--ssl-no-verify` Disables:

| Tool | Method | When Applied |
|------|--------|--------------|
| **git** | `git config --global http.sslVerify false` | Build time - git clone operations |
| **curl** | `-k` / `--insecure` flag | Build time - kubectl download |
| **bundler** | `bundle config ssl_verify_mode 0` | Build time - gem installation |
| **gem** | Force re-add gem sources | Build time - gem source access |
| **kubectl** | ❌ NOT HANDLED | Runtime - requires kubeconfig or flag |
| **docker** | ❌ NOT HANDLED | Build time - base image pulls |

### What Is NOT Affected:

1. **kubectl operations** - Must configure kubeconfig or use flags at runtime
2. **Docker base image pulls** - Must configure Docker daemon
3. **Runtime gem installations** - Only build-time gem installation affected

## Recommended Approach: Use Corporate Certificates

Instead of disabling SSL verification, **install corporate certificates**:

```bash
# Copy corporate CA bundle
cp $SSL_CERT_FILE certs/corporate-ca.pem

# Build with certificates (SSL verification stays enabled)
./scripts/build.sh
```

The Dockerfile will:
1. Copy certificates to `/usr/local/share/ca-certificates/corp/`
2. Convert formats if needed (.pem → .crt, .der → .pem)
3. Split certificate bundles
4. Run `update-ca-certificates` to add to system trust store

All tools (git, curl, bundler, etc.) will use the system trust store automatically.

## Testing SSL Configuration

### Test Git SSL:
```bash
docker run --rm cinc-auditor-alpine:latest \
  git clone https://github.com/mitre/train-k8s-container.git /tmp/test
```

### Test cURL SSL:
```bash
docker run --rm cinc-auditor-alpine:latest \
  curl -I https://rubygems.org
```

### Test Gem SSL:
```bash
docker run --rm cinc-auditor-alpine:latest \
  gem list --remote --all | head
```

### Test kubectl SSL (requires kubeconfig):
```bash
docker run --rm \
  -v ~/.kube/config:/home/auditor/.kube/config:ro \
  cinc-auditor-alpine:latest \
  kubectl get pods
```

## Troubleshooting

### Error: "SSL certificate problem: unable to get local issuer certificate"

**Solution 1 (Recommended):** Add corporate certificates
```bash
cp $SSL_CERT_FILE certs/corporate-ca.pem
./scripts/build.sh
```

**Solution 2 (Less secure):** Disable SSL verification
```bash
./scripts/build.sh --ssl-no-verify
```

### Error: "certificate verify failed" during gem install

Build was likely done without `--ssl-no-verify` or corporate certs. Rebuild:
```bash
./scripts/build.sh --ssl-no-verify --no-cache
```

### kubectl: "x509: certificate signed by unknown authority"

kubectl SSL is runtime config, not build. Fix kubeconfig:
```yaml
clusters:
- cluster:
    insecure-skip-tls-verify: true  # Add this line
    server: https://...
```

Or use flag:
```bash
kubectl --insecure-skip-tls-verify get pods
```

## Security Best Practices

1. ✅ **DO**: Use corporate certificates when possible
2. ✅ **DO**: Only disable SSL in controlled corporate environments
3. ✅ **DO**: Document why SSL verification is disabled
4. ❌ **DON'T**: Disable SSL in production
5. ❌ **DON'T**: Commit images with `--ssl-no-verify` to public registries
6. ❌ **DON'T**: Use `--ssl-no-verify` for public internet access
