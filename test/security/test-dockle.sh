#!/usr/bin/env bash
# Run Dockle security linting using containerized Dockle
# No local installation required

set -euo pipefail

IMAGE_TAG="${1:-cinc-auditor-alpine:6}"

echo "Running Dockle security linting on ${IMAGE_TAG}..."
echo ""

# Detect docker socket (OrbStack vs standard Docker)
if [ -S "$HOME/.orbstack/run/docker.sock" ]; then
    DOCKER_SOCK="$HOME/.orbstack/run/docker.sock"
else
    DOCKER_SOCK="/var/run/docker.sock"
fi

# Ignore expected warnings for CLI tool containers
docker run --rm \
  -v "${DOCKER_SOCK}:/var/run/docker.sock" \
  goodwithtech/dockle:latest \
  --ignore CIS-DI-0001 \
  --ignore DKL-LI-0003 \
  "${IMAGE_TAG}"

echo ""
echo "Note: Ignoring CIS-DI-0001 (root user) and DKL-LI-0003 (unnecessary files) - intentional for CLI tool container"
echo "✅ Dockle scan complete"
