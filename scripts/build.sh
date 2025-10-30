#!/usr/bin/env bash
# Build script for CINC Auditor Alpine Docker image

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
IMAGE_NAME="${IMAGE_NAME:-cinc-auditor-alpine}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
KUBECTL_VERSION="${KUBECTL_VERSION:-1.31.4}"
PLUGIN_GIT_REPO="${PLUGIN_GIT_REPO:-https://github.com/mitre/train-k8s-container.git}"
PLUGIN_GIT_BRANCH="${PLUGIN_GIT_BRANCH:-v2.0}"
SSL_NO_VERIFY="${SSL_NO_VERIFY:-false}"
ARCH="${ARCH:-amd64}"
PLATFORM="${PLATFORM:-}"
WITH_CERTS=false
NO_CACHE=false
DRY_RUN=false

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build CINC Auditor Alpine Docker image

OPTIONS:
    -h, --help              Show this help message
    -t, --tag TAG           Image tag (default: latest)
    -n, --name NAME         Image name (default: cinc-auditor-alpine)
    -k, --kubectl VERSION       kubectl version (default: 1.31.4)
    -a, --arch ARCH             Target architecture: amd64, arm64 (default: amd64)
    --platform PLATFORM         Full platform string (default: linux/amd64)
    --plugin-repo URL           Git repository URL for train plugin (default: mitre/train-k8s-container)
    --plugin-branch BRANCH      Git branch for plugin (default: v2.0)
    --ssl-no-verify             Disable SSL verification for git/curl/gem (corporate proxies)
    --with-certs                Include custom certificates from certs/ directory
    --no-cache                  Build without using cache
    --dry-run                   Show what would be built without building

EXAMPLES:
    # Dry run (see what would be built)
    $0 --dry-run

    # Basic build (amd64, kubectl 1.31.4)
    $0

    # Build with custom tag
    $0 --tag v1.0.0

    # Build for ARM64
    $0 --arch arm64

    # Build with specific kubectl version
    $0 --kubectl 1.29.0

    # Build with custom plugin from different git repo
    $0 --plugin-repo https://github.com/your-org/your-plugin.git --plugin-branch main

    # Build with SSL verification disabled (corporate proxies)
    $0 --ssl-no-verify

    # Build without cache
    $0 --no-cache

ENVIRONMENT VARIABLES:
    IMAGE_NAME              Override image name
    IMAGE_TAG               Override image tag
    KUBECTL_VERSION         kubectl version to install
    PLUGIN_GIT_REPO         Plugin git repository URL
    PLUGIN_GIT_BRANCH       Plugin git branch
    SSL_NO_VERIFY           Set to 'true' to disable SSL verification

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -k|--kubectl)
            KUBECTL_VERSION="$2"
            shift 2
            ;;
        -a|--arch)
            ARCH="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --plugin-repo)
            PLUGIN_GIT_REPO="$2"
            shift 2
            ;;
        --plugin-branch)
            PLUGIN_GIT_BRANCH="$2"
            shift 2
            ;;
        --ssl-no-verify)
            SSL_NO_VERIFY="true"
            shift
            ;;
        --with-certs)
            WITH_CERTS=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main build function
main() {
    log_info "Starting CINC Auditor Alpine Docker image build"
    log_info "Image: ${IMAGE_NAME}:${IMAGE_TAG}"

    # Set platform if not explicitly provided
    if [[ -z "$PLATFORM" ]]; then
        PLATFORM="linux/${ARCH}"
    fi

    # Validate architecture
    case "$ARCH" in
        amd64|arm64|arm|ppc64le|s390x)
            log_info "Target architecture: ${ARCH}"
            ;;
        *)
            log_warn "Unknown architecture: ${ARCH}, using anyway"
            ;;
    esac

    log_info "Platform: ${PLATFORM}"
    log_info "kubectl version: ${KUBECTL_VERSION}"
    log_info "Plugin git repo: ${PLUGIN_GIT_REPO}"
    log_info "Plugin git branch: ${PLUGIN_GIT_BRANCH}"
    if [[ "$SSL_NO_VERIFY" == "true" ]]; then
        log_warn "SSL verification is DISABLED (--ssl-no-verify)"
    fi

    # Check if Dockerfile exists
    if [[ ! -f "${PROJECT_ROOT}/Dockerfile" ]]; then
        log_error "Dockerfile not found at ${PROJECT_ROOT}/Dockerfile"
        exit 1
    fi

    # Check if Gemfile exists
    if [[ ! -f "${PROJECT_ROOT}/Gemfile" ]]; then
        log_error "Gemfile not found at ${PROJECT_ROOT}/Gemfile"
        exit 1
    fi

    # Check for certificates
    CERT_COUNT=0
    if [[ -d "${PROJECT_ROOT}/certs" ]]; then
        CERT_FILES=$(ls "${PROJECT_ROOT}/certs"/*.{pem,crt,cer,der} 2>/dev/null | grep -v README || true)
        if [[ -n "$CERT_FILES" ]]; then
            CERT_COUNT=$(echo "$CERT_FILES" | wc -l | tr -d ' ')
            log_info "Found ${CERT_COUNT} certificate file(s) in certs/:"
            echo "$CERT_FILES" | while read -r cert; do
                if [[ -n "$cert" ]]; then
                    log_info "  - $(basename "$cert")"
                fi
            done
        else
            log_info "No certificate files found in certs/"
        fi
    fi

    # Check for plugins
    PLUGIN_COUNT=0
    if [[ -d "${PROJECT_ROOT}/plugins" ]]; then
        PLUGIN_FILES=$(ls "${PROJECT_ROOT}/plugins"/*.gem 2>/dev/null || true)
        if [[ -n "$PLUGIN_FILES" ]]; then
            PLUGIN_COUNT=$(echo "$PLUGIN_FILES" | wc -l | tr -d ' ')
            log_info "Found ${PLUGIN_COUNT} plugin gem(s) in plugins/:"
            echo "$PLUGIN_FILES" | while read -r plugin; do
                if [[ -n "$plugin" ]]; then
                    log_info "  - $(basename "$plugin")"
                fi
            done
        else
            log_info "No plugin gems found in plugins/"
        fi
    fi

    # Build Docker command
    BUILD_ARGS=(
        "build"
        "--platform" "${PLATFORM}"
        "--build-arg" "KUBECTL_VERSION=${KUBECTL_VERSION}"
        "--build-arg" "PLUGIN_GIT_REPO=${PLUGIN_GIT_REPO}"
        "--build-arg" "PLUGIN_GIT_BRANCH=${PLUGIN_GIT_BRANCH}"
        "--build-arg" "SSL_NO_VERIFY=${SSL_NO_VERIFY}"
        "--tag" "${IMAGE_NAME}:${IMAGE_TAG}"
    )

    if [[ "$NO_CACHE" == "true" ]]; then
        BUILD_ARGS+=("--no-cache")
    fi

    # Add progress output for better visibility
    BUILD_ARGS+=("--progress=plain")

    BUILD_ARGS+=("${PROJECT_ROOT}")

    log_info ""
    log_info "Docker build command:"
    echo "  docker ${BUILD_ARGS[*]}"

    # Dry run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info ""
        log_info "================================"
        log_info "DRY RUN - No build will be executed"
        log_info "================================"
        log_info ""
        log_info "Build configuration:"
        log_info "  Image: ${IMAGE_NAME}:${IMAGE_TAG}"
        log_info "  Platform: ${PLATFORM}"
        log_info "  Architecture: ${ARCH}"
        log_info "  kubectl version: ${KUBECTL_VERSION}"
        log_info "  Plugin git repo: ${PLUGIN_GIT_REPO}"
        log_info "  Plugin git branch: ${PLUGIN_GIT_BRANCH}"
        log_info "  SSL verification: $([ "$SSL_NO_VERIFY" = "true" ] && echo "DISABLED" || echo "enabled")"
        log_info "  Certificates: ${CERT_COUNT} file(s)"
        log_info "  Plugin gems: ${PLUGIN_COUNT} file(s)"
        log_info "  No cache: ${NO_CACHE}"
        log_info ""
        log_info "To execute this build, run:"
        log_info "  ${0} $(echo "$@" | sed 's/--dry-run//')"
        return 0
    fi

    # Execute build
    log_info ""
    log_info "Starting build..."
    if docker "${BUILD_ARGS[@]}"; then
        log_info "✅ Build completed successfully!"
        log_info "Image: ${IMAGE_NAME}:${IMAGE_TAG}"

        # Show image info
        log_info "Image details:"
        docker images "${IMAGE_NAME}:${IMAGE_TAG}"

        # Show image size
        IMAGE_SIZE=$(docker inspect -f '{{ .Size }}' "${IMAGE_NAME}:${IMAGE_TAG}" | awk '{print $1/1024/1024 " MB"}')
        log_info "Image size: ${IMAGE_SIZE}"

        log_info ""
        log_info "Next steps:"
        log_info "  1. Run tests: ./scripts/test.sh"
        log_info "  2. Test manually: docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} cinc-auditor version"
        log_info "  3. Interactive shell: docker run -it --rm ${IMAGE_NAME}:${IMAGE_TAG} /bin/bash"

        return 0
    else
        log_error "❌ Build failed!"
        return 1
    fi
}

# Run main function
main
