# CINC Auditor Alpine Docker Image

A minimal, security-focused Docker image based on Alpine Linux with:
- **CINC Auditor** - Open source InSpec distribution
- **train-k8s-container v2.2.0** - Kubernetes container testing plugin
- **kubectl** - Kubernetes CLI tool
- **Custom certificate support** - For corporate environments

## Features

- ✅ Alpine Linux 3.19 (minimal attack surface)
- ✅ CINC Auditor (latest from rubygems.cinc.sh)
- ✅ train-k8s-container v2.2.0 plugin (from MITRE)
- ✅ kubectl (configurable version, default 1.31.4)
- ✅ Custom corporate certificate support (PEM, CRT, DER, CER formats)
- ✅ Certificate bundle auto-splitting
- ✅ Additional plugin installation from .gem files
- ✅ Multi-architecture support (amd64, arm64)
- ✅ Runs as root (standard for CLI tool containers)
- ✅ Health checks included

## Quick Start

### Build the Image

```bash
# Dry run (see what would be built)
./scripts/build.sh --dry-run

# Basic build (amd64, kubectl 1.31.4, train-k8s-container v2.2.0)
./scripts/build.sh

# Build for ARM64 (Apple Silicon, AWS Graviton, etc.)
./scripts/build.sh --arch arm64

# Build with specific kubectl version
./scripts/build.sh --kubectl 1.29.0

# Build with custom plugin from different git repo
./scripts/build.sh --plugin-repo https://github.com/your-org/your-plugin.git --plugin-branch main

# Build with SSL verification disabled (corporate proxies/VPNs)
./scripts/build.sh --ssl-no-verify

# Build without cache
./scripts/build.sh --no-cache
```

### Run Tests

```bash
# Run all tests
./scripts/test.sh

# Run specific test suite
./scripts/test.sh basic
./scripts/test.sh plugin
./scripts/test.sh kubernetes
```

### Use the Image

#### Basic Commands

```bash
# Check CINC Auditor version
docker run --rm cinc-auditor-alpine:latest cinc-auditor version

# List installed plugins
docker run --rm cinc-auditor-alpine:latest cinc-auditor plugin list

# Check kubectl version
docker run --rm cinc-auditor-alpine:latest kubectl version --client

# Interactive shell
docker run -it --rm cinc-auditor-alpine:latest /bin/bash
```

#### Kubernetes Container Scanning

Mount your kubeconfig to scan containers in Kubernetes:

```bash
# Detect platform in a K8s container
docker run --rm \
  -v ~/.kube/config:/root/.kube/config:ro \
  cinc-auditor-alpine:latest \
  cinc-auditor detect -t k8s-container://default/nginx-pod/nginx

# Run compliance profile
docker run --rm \
  -v ~/.kube/config:/root/.kube/config:ro \
  -v $(pwd)/my-profile:/workspace/profile:ro \
  cinc-auditor-alpine:latest \
  cinc-auditor exec /workspace/profile -t k8s-container://production/app-pod/app

# Interactive InSpec shell
docker run -it --rm \
  -v ~/.kube/config:/root/.kube/config:ro \
  cinc-auditor-alpine:latest \
  cinc-auditor shell -t k8s-container://default/my-pod/my-container
```

**Target Format:** `k8s-container://[namespace]/pod-name/container-name`

See `examples/k8s-scan.sh` for more examples.

## Docker Tags

Images are available on Docker Hub: `mitre/cinc-auditor-alpine`

### Tagging Strategy

Tags follow CINC Auditor upstream versions (no separate container versioning):

**CINC Auditor v6 (Stable):**
- `6.8.24` - Specific patch version
- `6.8` - Latest v6.8.x patch
- `6` - Latest v6.x release
- `latest` - Always points to latest stable v6

**CINC Auditor v7 (Stable):**
- `7.0.95` - Specific patch version
- `7.0` - Latest v7.0.x patch
- `7` - Latest v7.x release

**What's included in each tag:**
- CINC Auditor version (matches tag)
- train-k8s-container v2.2.0
- kubectl 1.31.4
- Multi-arch support (linux/amd64, linux/arm64)

### Examples

```bash
# Use specific CINC version (recommended for production)
docker pull mitre/cinc-auditor-alpine:6.8.24

# Use latest v6 patch (gets updates automatically)
docker pull mitre/cinc-auditor-alpine:6.8

# Use latest stable (currently v6)
docker pull mitre/cinc-auditor-alpine:latest

# Use CINC v7
docker pull mitre/cinc-auditor-alpine:7.0.95
```

## Project Structure

```
.
├── Dockerfile              # Alpine-based image with gem installation
├── Gemfile                # CINC Auditor gem dependencies
├── plugin-repos.txt       # List of plugin git repositories to install
├── plugin-repos.txt.example  # Example plugin repository list
├── README.md              # This file
├── TESTING.md             # Detailed testing documentation
├── certs/                 # Place custom certificates here (.pem, .crt, .der, .cer)
│   ├── .gitkeep
│   └── README.md
├── plugins/               # Place additional plugin .gem files here
│   ├── .gitkeep
│   └── README.md
├── examples/              # Usage examples
│   ├── basic-scan.sh
│   ├── k8s-scan.sh
│   └── profiles/
├── scripts/               # Build and test automation
│   ├── build.sh          # Build image with options
│   └── test.sh           # Run test suites
└── tests/                 # Test scripts
    ├── 01-basic.sh       # Basic functionality tests
    ├── 02-plugin.sh      # Plugin installation tests
    └── 03-kubernetes.sh  # K8s integration tests
```

## Custom Certificates

To add corporate certificates:

1. Place `.crt` files in the `certs/` directory
2. Build with: `./scripts/build.sh --with-certs`

Certificates will be automatically added to the system trust store.

## Requirements

### For Building:
- Docker 20.10+
- (Optional) Corporate CA certificates in `certs/` directory
- (Optional) Additional plugin `.gem` files in `plugins/` directory

### For Kubernetes Scanning:
- kubectl access to target Kubernetes cluster
- Valid kubeconfig file (typically `~/.kube/config`)
- Running pods/containers to scan
- (Optional) kind for local K8s cluster testing

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `KUBECONFIG` | `/root/.kube/config` | Path to kubeconfig file (runtime) |
| `TRAIN_K8S_SESSION_MODE` | `true` | Enable persistent PTY sessions (runtime) |
| `KUBECTL_VERSION` | `1.31.4` | kubectl version (build arg) |
| `PLUGIN_GIT_REPO` | `mitre/train-k8s-container` | Plugin git repository (build arg) |
| `PLUGIN_GIT_BRANCH` | `v2.2.0` | Plugin git branch (build arg) |
| `SSL_NO_VERIFY` | `false` | Disable SSL verification (build arg) |

## Security Features

- Minimal Alpine base (~540MB total image)
- Single-purpose container (CLI tool)
- No unnecessary packages
- CA certificate validation
- Multi-stage build (no build tools in final image)

## Troubleshooting

See [TESTING.md](TESTING.md) for detailed troubleshooting steps.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `./scripts/test.sh`
5. Submit a pull request

## License

Apache 2.0

## Maintainer

Aaron Lippold <lippold@gmail.com>
