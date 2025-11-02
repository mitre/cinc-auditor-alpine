#!/usr/bin/env bash
# Generate SBOM using containerized Syft
# No local installation required

set -euo pipefail

IMAGE_TAG="${1:-cinc-auditor-alpine:6}"
OUTPUT_FORMAT="${2:-table}"

echo "Generating SBOM for ${IMAGE_TAG} (format: ${OUTPUT_FORMAT})..."
echo ""

# Detect docker socket (OrbStack vs standard Docker)
if [ -S "$HOME/.orbstack/run/docker.sock" ]; then
    DOCKER_SOCK="$HOME/.orbstack/run/docker.sock"
else
    DOCKER_SOCK="/var/run/docker.sock"
fi

docker run --rm \
  -v "${DOCKER_SOCK}:/var/run/docker.sock" \
  anchore/syft:latest \
  "${IMAGE_TAG}" -o "${OUTPUT_FORMAT}"

echo ""
echo "✅ SBOM generation complete"
