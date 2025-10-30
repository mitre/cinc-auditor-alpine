#!/usr/bin/env bash
# Functional tests for CINC Auditor Alpine images
# Tests actual runtime functionality

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
IMAGE_TAG="${1:-cinc-auditor-alpine:latest}"
TESTS_PASSED=0
TESTS_FAILED=0

echo -e "${GREEN}Running functional tests for ${IMAGE_TAG}${NC}"
echo ""

# Helper functions
test_pass() {
    echo -e "  ${GREEN}✅ PASS${NC}: $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "  ${RED}❌ FAIL${NC}: $1"
    ((TESTS_FAILED++))
}

# Test 1: CINC Auditor version
echo "Test: CINC Auditor version output"
if docker run --rm "${IMAGE_TAG}" cinc-auditor version 2>&1 | grep -qE "[0-9]+\.[0-9]+"; then
    test_pass "CINC Auditor version returns valid version number"
else
    test_fail "CINC Auditor version failed"
fi

# Test 2: Plugin list
echo "Test: Plugin list"
if docker run --rm "${IMAGE_TAG}" cinc-auditor plugin list 2>&1 | grep -q "train-k8s-container"; then
    test_pass "train-k8s-container plugin is installed"
else
    test_fail "train-k8s-container plugin not found"
fi

# Test 3: kubectl
echo "Test: kubectl version"
if docker run --rm "${IMAGE_TAG}" kubectl version --client 2>&1 | grep -q "Client Version"; then
    test_pass "kubectl is installed and functional"
else
    test_fail "kubectl version failed"
fi

# Test 4: Ruby version
echo "Test: Ruby version"
if docker run --rm "${IMAGE_TAG}" ruby --version 2>&1 | grep -q "ruby 3\."; then
    test_pass "Ruby 3.x is installed"
else
    test_fail "Ruby version check failed"
fi

# Test 5: InSpec shell (basic syntax check)
echo "Test: InSpec can execute Ruby code"
if docker run --rm "${IMAGE_TAG}" sh -c 'echo "describe command(\"whoami\") do; its(\"stdout\") { should_not be_empty }; end" | cinc-auditor exec -' 2>&1 | grep -qE "1 successful|passed"; then
    test_pass "InSpec can execute basic tests"
else
    test_fail "InSpec execution test failed"
fi

# Test 6: Git initialized in workspace
echo "Test: Git repository in workspace"
if docker run --rm "${IMAGE_TAG}" sh -c "cd /workspace && git rev-parse --git-dir" 2>&1 | grep -q ".git"; then
    test_pass "Git repository exists in /workspace"
else
    test_fail "Git repository not found"
fi

# Summary
echo ""
echo "========================================"
echo "FUNCTIONAL TEST SUMMARY"
echo "========================================"
echo -e "${GREEN}Passed:  ${TESTS_PASSED}${NC}"
echo -e "${RED}Failed:  ${TESTS_FAILED}${NC}"
echo "========================================"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All tests passed${NC}"
    exit 0
fi
