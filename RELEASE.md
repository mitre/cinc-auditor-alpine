# Release Process

This document describes the release process for `cinc-auditor-alpine` Docker images.

## Versioning Strategy

**This project does NOT use semantic versioning for the container itself.**

Instead, we follow the industry standard pattern (used by `alpine/helm`, `chef/inspec`, `cincproject/auditor`) where **Docker image tags match the upstream tool versions**.

### Tag Structure

**CINC Auditor v6 (Stable):**
- `6.8.24` - Specific CINC version + kubectl + train-k8s-container versions  
- `6.8` - Floating tag (latest v6.8.x)
- `6` - Floating tag (latest v6.x)
- `latest` - Points to latest stable (currently v6)

**CINC Auditor v7 (Stable):**
- `7.0.95` - Specific CINC version + dependencies
- `7.0` - Floating tag (latest v7.0.x)
- `7` - Floating tag (latest v7.x)

## When to Release

Release new images when:
1. **New CINC Auditor version** released on rubygems.cinc.sh
2. **kubectl security updates** (CVEs, critical patches)
3. **train-k8s-container updates** (new features, bug fixes)
4. **Alpine base image** security updates

## Release Workflow

### 1. Create Feature Branch

\`\`\`bash
# From main branch
git checkout main
git pull origin main

# Create feature branch
git checkout -b fix/update-kubectl-1.32.11
# OR
git checkout -b feat/cinc-7.1.0
\`\`\`

### 2. Update Versions

Update the appropriate files:

**For CINC Auditor updates:**
- `Gemfile.v6` or `Gemfile.v7` - Update gem versions
- `docker-bake.hcl` - Update specific version tags
- Test files if version-specific changes needed

**For kubectl updates:**
- `docker-bake.hcl` - Update `KUBECTL_VERSION` variable  
- Affects ALL images (both v6 and v7)

**For train-k8s-container updates:**
- `plugin-repos.txt.example` - Update branch/tag
- `docker-bake.hcl` - Update `PLUGIN_GIT_BRANCH` variable
- `test/goss/goss.yaml` - Update version expectation

### 3. Test Locally

\`\`\`bash
# Build locally (your architecture only)
docker buildx bake v6  # Test CINC v6
docker buildx bake v7  # Test CINC v7

# Run tests
./test/goss/test-with-goss.sh cinc-auditor-alpine:6 goss-vars-v6.yaml
./test/goss/test-with-goss.sh cinc-auditor-alpine:7 goss-vars-v7.yaml
\`\`\`

### 4. Commit and Push

\`\`\`bash
git add <changed-files>
git commit -m "feat: update kubectl to 1.32.11

- Update kubectl from 1.31.4 to 1.32.11
- Addresses CVE-XXXX-XXXX
- Rebuild all tags

Authored by: Aaron Lippold <lippold@gmail.com>"

git push origin fix/update-kubectl-1.32.11
\`\`\`

### 5. Create Pull Request

\`\`\`bash
gh pr create --title "Update kubectl to 1.32.11" \\
  --body "Fixes CVE-XXXX-XXXX by updating kubectl"
\`\`\`

### 6. Merge to Main

After PR approval and CI passing, merge via GitHub UI (squash and merge).

### 7. Trigger Release Workflow

\`\`\`bash
# After merge to main
git checkout main
git pull origin main

# Trigger Docker Hub release  
gh workflow run release.yml --repo mitre/cinc-auditor-alpine
\`\`\`

### 8. Verify Release

\`\`\`bash
# Check Docker Hub
curl -s "https://hub.docker.com/v2/repositories/mitre/cinc-auditor-alpine/tags/?page_size=20" \\
  | jq -r '.results[] | "\\(.name) - \\(.last_updated)"'

# Test images
docker pull mitre/cinc-auditor-alpine:6.8.24
docker run --rm mitre/cinc-auditor-alpine:6.8.24 cinc-auditor version
docker run --rm mitre/cinc-auditor-alpine:6.8.24 kubectl version --client
\`\`\`

## CHANGELOG Updates

Update `CHANGELOG.md` with each release - see CHANGELOG.md for format.

## Rollback Procedure

If a release has critical issues:

\`\`\`bash
# Revert the problematic commit
git revert <commit-hash>
git push origin main

# Trigger new release
gh workflow run release.yml
\`\`\`

## Troubleshooting

### Build Fails with 401 Unauthorized
- Recreate Docker Hub access token with `scope-image-push` for `mitre/*`
- Update GitHub org secret `DOCKER_PAT`

### Multi-arch Build Slow  
- Verify using Docker Build Cloud (`driver: cloud`)

Authored by: Aaron Lippold <lippold@gmail.com>
