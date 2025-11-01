#!/usr/bin/env bash
# Run all test suites for CINC Auditor Alpine images

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_TAG="${1:-cinc-auditor-alpine:latest}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  CINC Auditor Alpine Test Suite${NC}"
echo -e "${BLUE}  Image: ${IMAGE_TAG}${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Test 1: Hadolint - Dockerfile linting
echo -e "${GREEN}[1/3] Running Hadolint (Dockerfile linting)...${NC}"
if command -v hadolint &> /dev/null; then
    cd "${PROJECT_ROOT}"
    if hadolint Dockerfile; then
        echo -e "${GREEN}✅ Hadolint passed${NC}"
    else
        echo -e "${RED}❌ Hadolint failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Hadolint not installed, skipping${NC}"
    echo "   Install: brew install hadolint"
fi
echo ""

# Test 2: Container Structure Test
echo -e "${GREEN}[2/3] Running Container Structure Tests...${NC}"
if command -v container-structure-test &> /dev/null; then
    cd "${PROJECT_ROOT}"

    # Detect Docker socket location (OrbStack vs standard Docker)
    if [ -S "$HOME/.orbstack/run/docker.sock" ]; then
        echo "  Detected OrbStack - using ~/.orbstack/run/docker.sock"
        export DOCKER_HOST="unix://$HOME/.orbstack/run/docker.sock"
    elif [ -S "/var/run/docker.sock" ]; then
        echo "  Detected standard Docker - using /var/run/docker.sock"
        export DOCKER_HOST="unix:///var/run/docker.sock"
    else
        echo -e "${RED}❌ No Docker socket found${NC}"
        echo "   Checked: ~/.orbstack/run/docker.sock and /var/run/docker.sock"
        exit 1
    fi

    if container-structure-test test --image "${IMAGE_TAG}" --config container-structure-test.yaml; then
        echo -e "${GREEN}✅ Container structure tests passed${NC}"
    else
        echo -e "${RED}❌ Container structure tests failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  container-structure-test not installed, skipping${NC}"
    echo "   Install: https://github.com/GoogleContainerTools/container-structure-test"
fi
echo ""

# Test 3: Functional tests
echo -e "${GREEN}[3/3] Running Functional Tests...${NC}"
if "${PROJECT_ROOT}/tests/test-functional.sh" "${IMAGE_TAG}"; then
    echo -e "${GREEN}✅ Functional tests passed${NC}"
else
    echo -e "${RED}❌ Functional tests failed${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✅ All test suites passed!${NC}"
echo -e "${GREEN}======================================${NC}"
