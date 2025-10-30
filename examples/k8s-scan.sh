#!/usr/bin/env bash
# Example: Scanning Kubernetes containers with CINC Auditor

set -euo pipefail

# Configuration
IMAGE_NAME="${IMAGE_NAME:-cinc-auditor-alpine:latest}"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}CINC Auditor Kubernetes Container Scanning Examples${NC}"
echo ""

# Example 1: Detect platform
echo -e "${YELLOW}Example 1: Detect platform in a K8s container${NC}"
echo "Command: cinc-auditor detect -t k8s-container://default/test-pod/test-container"
echo ""
docker run --rm \
  -v "${KUBECONFIG}:/root/.kube/config:ro" \
  "${IMAGE_NAME}" \
  cinc-auditor detect -t k8s-container://default/test-pod/test-container
echo ""

# Example 2: Run commands interactively
echo -e "${YELLOW}Example 2: Interactive InSpec shell${NC}"
echo "Command: cinc-auditor shell -t k8s-container://default/test-pod/test-container"
echo ""
docker run -it --rm \
  -v "${KUBECONFIG}:/root/.kube/config:ro" \
  "${IMAGE_NAME}" \
  cinc-auditor shell -t k8s-container://default/test-pod/test-container
echo ""

# Example 3: Run a profile
echo -e "${YELLOW}Example 3: Run compliance profile${NC}"
echo "Command: cinc-auditor exec https://github.com/dev-sec/linux-baseline"
echo ""
docker run --rm \
  -v "${KUBECONFIG}:/root/.kube/config:ro" \
  "${IMAGE_NAME}" \
  cinc-auditor exec https://github.com/dev-sec/linux-baseline \
    -t k8s-container://default/ubuntu-pod/ubuntu
echo ""

# Example 4: Generate JSON report
echo -e "${YELLOW}Example 4: Generate JSON report${NC}"
echo "Saving results to ./reports/scan-results.json"
mkdir -p ./reports
docker run --rm \
  -v "${KUBECONFIG}:/root/.kube/config:ro" \
  -v "$(pwd)/reports:/workspace/reports" \
  "${IMAGE_NAME}" \
  cinc-auditor exec https://github.com/dev-sec/linux-baseline \
    -t k8s-container://default/app-pod/app \
    --reporter json:/workspace/reports/scan-results.json
echo ""

echo -e "${GREEN}Examples complete!${NC}"
