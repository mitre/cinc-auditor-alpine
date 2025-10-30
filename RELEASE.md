# Release Process

## Docker Hub Publishing

### Prerequisites
1. Docker Hub account
2. Create repository: `your-username/cinc-auditor-alpine`
3. Generate access token at https://hub.docker.com/settings/security
4. Add GitHub secrets:
   - `DOCKERHUB_USERNAME` - Your Docker Hub username
   - `DOCKERHUB_TOKEN` - Your access token

### Automated Release (Recommended)

1. **Create a GitHub release:**
   ```bash
   # Tag the release
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

2. **GitHub Actions will automatically:**
   - Build both v6 and v7
   - Build for amd64 and arm64
   - Run all tests
   - Push to Docker Hub
   - Update Docker Hub description

### Manual Release

```bash
# Build and push v6 multi-arch
docker buildx bake --push v6-multiarch

# Build and push v7 multi-arch
docker buildx bake --push v7-multiarch

# Or push both at once
docker buildx bake --push all
```

## Version Tagging Strategy

### CINC Auditor Versions
- `:6`, `:6.8`, `:6.8.24`, `:latest` → v6 stable
- `:7`, `:7.0`, `:7.0.52.beta` → v7 beta

### Project Releases
- `v1.0.0` - Initial stable release
- `v1.1.0` - Minor updates (kubectl version, plugins)
- `v2.0.0` - Major changes (base image, architecture)

## Pre-Release Checklist

- [ ] All tests pass locally
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version numbers correct in docker-bake.hcl
- [ ] Both v6 and v7 build successfully
- [ ] Multi-arch builds tested

## Testing Before Release

```bash
# Lint Dockerfile
hadolint Dockerfile

# Build all variants
docker buildx bake

# Test v6
./scripts/test-all.sh cinc-auditor-alpine:6

# Test v7
./scripts/test-all.sh cinc-auditor-alpine:7

# Test with Kubernetes (if available)
docker run --rm \
  -v ~/.kube/config:/root/.kube/config:ro \
  cinc-auditor-alpine:6 \
  cinc-auditor detect -t k8s-container://default/test-pod/test
```

## Post-Release

1. Verify images on Docker Hub
2. Test pulling from Docker Hub
3. Update project documentation with image tags
4. Announce in relevant communities

## Rollback

If a release has issues:

```bash
# Remove tags from Docker Hub
docker push --delete your-username/cinc-auditor-alpine:problematic-tag

# Re-release previous version
git tag -d v1.0.1
git push origin :refs/tags/v1.0.1
```
