#!/usr/bin/env bash
# Run Trivy vulnerability scanning using containerized Trivy
# No local installation required

set -euo pipefail

IMAGE_TAG="${1:-cinc-auditor-alpine:6}"

echo "Running Trivy vulnerability scan on ${IMAGE_TAG}..."
echo ""

# Detect docker socket (OrbStack vs standard Docker)
if [ -S "$HOME/.orbstack/run/docker.sock" ]; then
    DOCKER_SOCK="$HOME/.orbstack/run/docker.sock"
else
    DOCKER_SOCK="/var/run/docker.sock"
fi

docker run --rm \
  -v "${DOCKER_SOCK}:/var/run/docker.sock" \
  aquasec/trivy:latest \
  image --severity HIGH,CRITICAL "${IMAGE_TAG}"

echo ""
echo "✅ Trivy scan complete"
