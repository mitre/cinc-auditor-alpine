#!/usr/bin/env bash
# Test CINC Auditor Alpine images using Goss (no local install needed!)
# Downloads goss binary into the target container and runs tests

set -euo pipefail

IMAGE_TAG="${1:-cinc-auditor-alpine:6}"
VARS_FILE="${2:-goss-vars-v6.yaml}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Testing ${IMAGE_TAG} with Goss..."
echo "Using vars file: ${VARS_FILE}"
echo ""

# Run target container with goss files mounted, download goss binary, execute tests
docker run --rm \
  -v "${SCRIPT_DIR}/goss.yaml:/goss.yaml:ro" \
  -v "${SCRIPT_DIR}/${VARS_FILE}:/vars.yaml:ro" \
  --entrypoint /bin/sh \
  "${IMAGE_TAG}" \
  -c "wget -q -O /tmp/goss https://github.com/goss-org/goss/releases/latest/download/goss-linux-\$(uname -m | sed 's/aarch64/arm64/' | sed 's/x86_64/amd64/') && chmod +x /tmp/goss && cd / && /tmp/goss --vars /vars.yaml --gossfile /goss.yaml validate"

echo ""
echo "✅ Goss tests passed for ${IMAGE_TAG}"
