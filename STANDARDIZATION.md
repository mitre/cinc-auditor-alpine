# Project Standardization - Ruby 3.4 + Docker Bake

## Changes Made

### Base Image
- **Old:** `alpine:3.19` + install Ruby 3.2.8
- **New:** `ruby:3.4-alpine` (Alpine 3.22 + Ruby 3.4.7 pre-installed)

**Benefits:**
- ✅ Latest Ruby 3.4.7
- ✅ Simpler Dockerfile (Ruby already installed)
- ✅ Better long-term support
- ✅ Works for both v6 and v7

**Trade-off:**
- ⚠️ ~100MB larger (658MB vs 549MB)
- Reason: More complete Ruby installation (54.7MB vs 15.3MB)

### Build System
- **Primary:** Docker Bake (`docker buildx bake`)
- **Legacy:** build.sh script (still supported)

**Why Docker Bake:**
- ✅ Modern, declarative approach
- ✅ Parallel builds (v6 AND v7 at once)
- ✅ Multi-arch support (amd64 + arm64 concurrently)
- ✅ Industry standard (CINC, polymathrobotics use it)
- ✅ Better CI/CD integration

## File Structure

**Core:**
- `Dockerfile` - Single file for all variants
- `Gemfile.v6` - CINC 6.8.x dependencies
- `Gemfile.v7` - CINC 7 stable dependencies
- `docker-bake.hcl` - Build configuration

**Documentation:**
- `QUICKSTART.md` - Get started fast
- `DOCKER-BAKE.md` - Bake usage guide
- `README.md` - Full documentation

**Kept for compatibility:**
- `scripts/build.sh` - Legacy build script
- `scripts/test.sh` - Test suite
- `Gemfile` - Points to v6 (default)

## Build Commands

**New way (recommended):**
```bash
docker buildx bake v6              # Build v6 (local arch)
docker buildx bake v7              # Build v7 (local arch)
docker buildx bake                 # Build both
docker buildx bake all             # Build both (multi-arch)
```

**Old way (still works):**
```bash
./scripts/build.sh --tag v6
```

## Versions Available

| Tag | CINC Version | Status | Ruby |
|-----|--------------|--------|------|
| `:6`, `:6.8`, `:6.8.24`, `:latest` | 6.8.24 | Stable | 3.4.x |
| `:7`, `:7.0`, `:7.0.95` | 7.0.95 | Stable | 3.4.x |

## Image Sizes

- v6: ~658MB
- v7: ~645MB

## Next Steps

1. ✅ Standardized on Ruby 3.4 + Docker Bake
2. ⏭️ Set up CI/CD (GitHub Actions)
3. ⏭️ Create automated tests
4. ⏭️ Configure Docker Hub publishing
5. ⏭️ Fix SSL/VPN certificate handling
