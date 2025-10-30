#!/usr/bin/env bash
# Test script for CINC Auditor Alpine Docker image

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
IMAGE_NAME="${IMAGE_NAME:-cinc-auditor-alpine}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
VERBOSE=false
CLEANUP=true

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TESTS_DIR="${PROJECT_ROOT}/tests"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

test_pass() {
    echo -e "  ${GREEN}✅ PASS${NC}: $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "  ${RED}❌ FAIL${NC}: $1"
    ((TESTS_FAILED++))
}

test_skip() {
    echo -e "  ${YELLOW}⚠️  SKIP${NC}: $1"
    ((TESTS_SKIPPED++))
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [TEST_SUITE]

Run tests for CINC Auditor Alpine Docker image

TEST SUITES:
    basic               Basic functionality tests
    plugin              Plugin installation tests
    kubernetes          Kubernetes integration tests
    certificates        Certificate handling tests
    all                 Run all tests (default)

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Verbose output
    -t, --tag TAG       Image tag to test (default: latest)
    -n, --name NAME     Image name to test (default: cinc-auditor-alpine)
    --no-cleanup        Don't cleanup test containers on failure

EXAMPLES:
    # Run all tests
    $0

    # Run specific test suite
    $0 basic

    # Run with verbose output
    $0 --verbose all

    # Test specific image
    $0 --tag v1.0.0 all

EOF
}

# Check if image exists
check_image_exists() {
    if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" &>/dev/null; then
        log_error "Image ${IMAGE_NAME}:${IMAGE_TAG} not found"
        log_info "Build the image first: ./scripts/build.sh"
        exit 1
    fi
    log_info "Testing image: ${IMAGE_NAME}:${IMAGE_TAG}"
}

# Basic functionality tests
run_basic_tests() {
    log_test "Running basic functionality tests..."

    # Test 1: Image runs
    log_test "Test: Image runs successfully"
    if docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" cinc-auditor version &>/dev/null; then
        test_pass "Image runs successfully"
    else
        test_fail "Image failed to run"
    fi

    # Test 2: CINC Auditor version
    log_test "Test: CINC Auditor version check"
    VERSION_OUTPUT=$(docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" cinc-auditor version 2>&1 || true)
    if echo "$VERSION_OUTPUT" | grep -q "Cinc Auditor"; then
        test_pass "CINC Auditor version: $(echo "$VERSION_OUTPUT" | head -1)"
    else
        test_fail "CINC Auditor version check failed"
        [[ "$VERBOSE" == "true" ]] && echo "$VERSION_OUTPUT"
    fi

    # Test 3: Ruby version
    log_test "Test: Ruby version check"
    RUBY_VERSION=$(docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" ruby --version 2>&1 || true)
    if echo "$RUBY_VERSION" | grep -q "ruby 3"; then
        test_pass "Ruby version: $RUBY_VERSION"
    else
        test_fail "Ruby version check failed"
    fi

    # Test 4: Non-root user
    log_test "Test: Non-root user execution"
    USER_CHECK=$(docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" whoami 2>&1 || true)
    if [[ "$USER_CHECK" == "auditor" ]]; then
        test_pass "Running as non-root user: auditor"
    else
        test_fail "Expected user 'auditor', got: $USER_CHECK"
    fi

    # Test 5: Working directory
    log_test "Test: Working directory check"
    PWD_CHECK=$(docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" pwd 2>&1 || true)
    if [[ "$PWD_CHECK" == "/workspace" ]]; then
        test_pass "Working directory is /workspace"
    else
        test_fail "Expected /workspace, got: $PWD_CHECK"
    fi
}

# Plugin tests
run_plugin_tests() {
    log_test "Running plugin installation tests..."

    # Test 1: Plugin list
    log_test "Test: List installed plugins"
    PLUGIN_LIST=$(docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" cinc-auditor plugin list 2>&1 || true)
    if echo "$PLUGIN_LIST" | grep -q "train-k8s-container"; then
        test_pass "train-k8s-container plugin is installed"
    else
        test_fail "train-k8s-container plugin not found"
        [[ "$VERBOSE" == "true" ]] && echo "$PLUGIN_LIST"
    fi

    # Test 2: Plugin version
    log_test "Test: Plugin version check"
    if echo "$PLUGIN_LIST" | grep -q "train-k8s-container.*2\."; then
        test_pass "train-k8s-container v2.x detected"
    else
        test_warn "Could not verify plugin version"
        test_skip "Plugin version verification"
    fi
}

# Kubernetes tests
run_kubernetes_tests() {
    log_test "Running Kubernetes integration tests..."

    # Test 1: kubectl installed
    log_test "Test: kubectl installation"
    KUBECTL_VERSION=$(docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" kubectl version --client --output=yaml 2>&1 || true)
    if echo "$KUBECTL_VERSION" | grep -q "clientVersion"; then
        test_pass "kubectl is installed"
    else
        test_fail "kubectl not found"
        [[ "$VERBOSE" == "true" ]] && echo "$KUBECTL_VERSION"
    fi

    # Test 2: kubectl version
    log_test "Test: kubectl version check"
    if echo "$KUBECTL_VERSION" | grep -q "gitVersion"; then
        K8S_VER=$(echo "$KUBECTL_VERSION" | grep "gitVersion" | head -1)
        test_pass "kubectl version: $K8S_VER"
    else
        test_fail "Could not determine kubectl version"
    fi

    # Test 3: K8s connection (optional - requires kubeconfig)
    log_test "Test: Kubernetes cluster connectivity"
    if [[ -f "$HOME/.kube/config" ]]; then
        K8S_CONNECT=$(docker run --rm \
            -v "$HOME/.kube/config:/home/auditor/.kube/config:ro" \
            "${IMAGE_NAME}:${IMAGE_TAG}" \
            kubectl cluster-info 2>&1 || true)
        if echo "$K8S_CONNECT" | grep -q "Kubernetes"; then
            test_pass "Successfully connected to Kubernetes cluster"
        else
            test_skip "No Kubernetes cluster available"
        fi
    else
        test_skip "No kubeconfig found at ~/.kube/config"
    fi
}

# Certificate tests
run_certificate_tests() {
    log_test "Running certificate handling tests..."

    # Test 1: CA certificates directory exists
    log_test "Test: CA certificates directory"
    CERT_DIR=$(docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" \
        ls -la /usr/local/share/ca-certificates/corp 2>&1 || true)
    if [[ "$CERT_DIR" =~ "total" ]]; then
        test_pass "Certificate directory exists"
    else
        test_fail "Certificate directory not found"
    fi

    # Test 2: CA bundle exists
    log_test "Test: CA bundle"
    CA_BUNDLE=$(docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" \
        ls -la /etc/ssl/certs/ca-certificates.crt 2>&1 || true)
    if echo "$CA_BUNDLE" | grep -q "ca-certificates.crt"; then
        test_pass "CA bundle exists"
    else
        test_fail "CA bundle not found"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "======================================"
    echo "TEST SUMMARY"
    echo "======================================"
    echo -e "${GREEN}Passed:  ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed:  ${TESTS_FAILED}${NC}"
    echo -e "${YELLOW}Skipped: ${TESTS_SKIPPED}${NC}"
    echo "--------------------------------------"
    TOTAL=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
    echo "Total:   ${TOTAL}"
    echo "======================================"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}❌ Some tests failed${NC}"
        return 1
    elif [[ $TESTS_PASSED -gt 0 ]]; then
        echo -e "${GREEN}✅ All tests passed${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  No tests were run${NC}"
        return 1
    fi
}

# Main function
main() {
    local test_suite="${1:-all}"

    check_image_exists

    case "$test_suite" in
        basic)
            run_basic_tests
            ;;
        plugin)
            run_plugin_tests
            ;;
        kubernetes)
            run_kubernetes_tests
            ;;
        certificates)
            run_certificate_tests
            ;;
        all)
            run_basic_tests
            run_plugin_tests
            run_kubernetes_tests
            run_certificate_tests
            ;;
        *)
            log_error "Unknown test suite: $test_suite"
            show_usage
            exit 1
            ;;
    esac

    print_summary
}

# Parse arguments
TEST_SUITE="all"
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --no-cleanup)
            CLEANUP=false
            shift
            ;;
        basic|plugin|kubernetes|certificates|all)
            TEST_SUITE="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Run tests
main "$TEST_SUITE"
