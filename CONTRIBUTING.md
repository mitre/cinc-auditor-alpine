# Contributing to CINC Auditor Alpine

Thank you for your interest in contributing to the CINC Auditor Alpine Docker image!

## Branch Protection

The `main` branch is protected with the following requirements:

### Required Status Checks

All pull requests must pass these checks before merging:

1. **lint** - Hadolint Dockerfile linting
2. **build-and-test (v6)** - CINC Auditor v6 build and test suite
3. **build-and-test (v7)** - CINC Auditor v7 build and test suite

### Protection Settings

- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Enforce for administrators (no bypass)
- ❌ No pull request reviews required (automated quality checks only)

This ensures broken code cannot be merged to `main` and released to Docker Hub.

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout main
git pull origin main
git checkout -b fix/your-feature-name
```

### 2. Make Your Changes

- Edit relevant files (Dockerfile, tests, documentation)
- Test locally using `./scripts/build.sh` and `./scripts/test.sh`
- Follow existing patterns and conventions

### 3. Run Tests Locally

```bash
# Build image
./scripts/build.sh

# Run all tests
./scripts/test.sh

# Run specific test suite
./scripts/test.sh basic
./scripts/test.sh plugin
./scripts/test.sh kubernetes
```

### 4. Create Pull Request

```bash
git add <specific-files>
git commit -m "fix: descriptive message"
git push origin fix/your-feature-name
```

Then open a pull request on GitHub targeting the `main` branch.

### 5. CI/CD Checks

GitHub Actions will automatically run:

- Hadolint linting
- Multi-arch builds (amd64, arm64)
- Container structure tests
- InSpec functional tests
- Goss validation tests
- Trivy vulnerability scanning
- Syft SBOM generation
- Dockle security linting

All checks must pass before the PR can be merged.

## Testing Requirements

### Dockerfile Changes

If you modify the Dockerfile:
- Run Hadolint locally: `hadolint Dockerfile`
- Test both v6 and v7 builds
- Verify all tests pass for both versions

### Dependency Updates

If you update kubectl, CINC Auditor, or plugin versions:
- Update `docker-bake.hcl` (single source of truth)
- Test version changes do not break functionality
- Run full test suite

### Test Changes

If you modify tests:
- Ensure tests are version-agnostic (no hardcoded versions)
- Use regex patterns for version checks
- Test with both v6 and v7 images

## Commit Message Format

Use conventional commit prefixes:

- `feat:` - New feature
- `fix:` - Bug fix
- `test:` - Test changes
- `docs:` - Documentation only
- `chore:` - Maintenance tasks
- `ci:` - CI/CD changes

Example:
```
fix: update kubectl to 1.32.11 for CVE remediation

- Updates kubectl from 1.31.4 to 1.32.11
- Fixes CVE-2024-XXXXX
- All tests passing
```

## Release Process

Releases are managed through Docker Hub:

1. Changes merged to `main` branch
2. Manual release triggered via GitHub Actions workflow
3. Multi-arch images built with Docker Build Cloud
4. Images pushed to Docker Hub with version tags

Weekly automated rebuilds occur every Monday at 2 AM UTC to pick up security updates.

## Code Quality Standards

- **WE DO NOT COMMIT BROKEN CODE EVER**
- All CI checks must pass
- No hardcoded versions (use docker-bake.hcl)
- DRY principle - single source of truth
- Security-first approach

## Questions or Issues?

- Open an issue: https://github.com/mitre/cinc-auditor-alpine/issues
- Check existing documentation in README.md and TESTING.md

## License

Apache 2.0

Authored by: Aaron Lippold <lippold@gmail.com>
