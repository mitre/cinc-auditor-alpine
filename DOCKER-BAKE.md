# Docker Bake Usage Guide

Docker Bake provides a modern, declarative way to build multiple image variants.

## Quick Start

```bash
# Build all targets (v6 and v7) for local architecture
docker buildx bake

# Build specific version
docker buildx bake v6
docker buildx bake v7

# Build multi-architecture images (amd64 + arm64)
docker buildx bake all

# Build specific version multi-arch
docker buildx bake v6-multiarch
docker buildx bake v7-multiarch
```

## Available Targets

| Target | Description | Platforms | Tags |
|--------|-------------|-----------|------|
| `v6` | CINC v6.8 stable (local arch) | Your platform | `:6`, `:6.8`, `:latest` |
| `v7` | CINC v7 stable (local arch) | Your platform | `:7`, `:7.0`, `:7.0.95` |
| `v6-multiarch` | CINC v6.8 stable (multi-arch) | amd64, arm64 | `:6`, `:6.8`, `:latest` |
| `v7-multiarch` | CINC v7 stable (multi-arch) | amd64, arm64 | `:7`, `:7.0`, `:7.0.95` |
| `dev-vpn` | Dev build with SSL bypass | Your platform | `:dev-vpn` |

## Groups

```bash
# Build all versions (local platform)
docker buildx bake default

# Build all versions (multi-arch)
docker buildx bake all
```

## Customization

Override variables:

```bash
# Custom kubectl version
docker buildx bake --set "*.args.KUBECTL_VERSION=1.29.0" v6

# Custom tag prefix
docker buildx bake --set TAG_PREFIX=myregistry/cinc v6

# SSL bypass for corporate VPN
docker buildx bake --set "*.args.SSL_NO_VERIFY=true" v6

# Custom plugin
docker buildx bake \
  --set "*.args.PLUGIN_GIT_REPO=https://github.com/your-org/plugin.git" \
  --set "*.args.PLUGIN_GIT_BRANCH=main" \
  v6
```

## Push to Registry

```bash
# Build and push to registry
docker buildx bake --push v6-multiarch

# Push all multi-arch images
docker buildx bake --push all
```

## Advantages over build.sh

| Feature | build.sh | Docker Bake |
|---------|----------|-------------|
| Build multiple versions | Sequential | **Parallel** ✅ |
| Multi-arch | One at a time | **Concurrent** ✅ |
| Configuration | Command flags | **Declarative file** ✅ |
| Maintainability | Bash script | **HCL config** ✅ |
| CI/CD | Custom scripts | **Native support** ✅ |

## Requirements

- Docker Desktop 4.x+ (includes buildx)
- OR Docker Engine with buildx plugin

Check if available:
```bash
docker buildx version
```

## Migration

**Old way:**
```bash
./scripts/build.sh --arch arm64 --tag v6
./scripts/build.sh --cinc-version 7 --arch arm64 --tag v7
```

**New way:**
```bash
docker buildx bake all
```

## Local Development

```bash
# Quick test build (local arch only)
docker buildx bake v7

# Full multi-arch build
docker buildx bake v7-multiarch
```

## See Also

- `docker-bake.hcl` - Build configuration
- `./scripts/build.sh` - Legacy build script (still supported)
- [Docker Bake Documentation](https://docs.docker.com/build/bake/)
