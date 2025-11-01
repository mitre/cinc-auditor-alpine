# CINC Auditor Alpine with train-k8s-container and kubectl
# Based on official CINC Project docker-images repository
# https://gitlab.com/cinc-project/docker-images/-/tree/master/docker-auditor

FROM ruby:3.4-alpine AS base-linux-amd64
FROM ruby:3.4-alpine AS base-linux-arm64

# Final stage
FROM base-linux-${TARGETARCH}

# Set shell to ash with pipefail for better error handling
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Build arguments - declare at top for availability throughout build
ARG SSL_NO_VERIFY=false
ARG KUBECTL_VERSION=1.31.4
ARG CINC_MAJOR_VERSION=6
ARG PLUGIN_GIT_REPO=https://github.com/mitre/train-k8s-container.git
ARG PLUGIN_GIT_BRANCH=v2.0

LABEL maintainer="Aaron Lippold <lippold@gmail.com>" \
      description="CINC Auditor with train-k8s-container plugin and kubectl" \
      version="1.0.0"

# Handle SSL verification for corporate environments
# Install ca-certificates first, then add corporate certs BEFORE any other downloads
COPY certs/ /tmp/corp-certs/
WORKDIR /tmp/corp-certs
RUN if [ "$SSL_NO_VERIFY" = "true" ]; then \
        echo "WARNING: Using HTTP repos for Alpine packages (corporate SSL proxy/VPN)"; \
        echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/main" > /etc/apk/repositories && \
        echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories; \
    fi && \
    apk add --no-cache ca-certificates openssl coreutils && \
    mkdir -p /usr/local/share/ca-certificates/corp && \
    # Process all certificate files - split bundles into individual certs
    for certfile in ./*.pem ./*.crt; do \
        test -f "$certfile" || continue; \
        cert_count=$(grep -c "BEGIN CERTIFICATE" "$certfile" || echo "0"); \
        echo "Processing $certfile ($cert_count certificates)"; \
        if [ "$cert_count" -gt 1 ]; then \
            csplit -s -z -f "cert-" "$certfile" '/-----BEGIN CERTIFICATE-----/' '{*}'; \
            for splitfile in cert-*; do \
                test -f "$splitfile" && mv "$splitfile" "/usr/local/share/ca-certificates/corp/${splitfile}.crt"; \
            done; \
        else \
            cp "$certfile" "/usr/local/share/ca-certificates/corp/$(basename "$certfile" .pem).crt"; \
        fi; \
    done && \
    update-ca-certificates && \
    echo "Corporate certificates installed and trusted"

# Install build and runtime dependencies
RUN apk add --update --no-cache \
    build-base \
    libxml2-dev \
    libffi-dev \
    git \
    openssh-client \
    ruby-dev \
    bash \
    curl \
    wget

# Install kubectl
RUN echo "Installing kubectl v${KUBECTL_VERSION}..." && \
    if [ "$SSL_NO_VERIFY" = "true" ]; then \
        echo "WARNING: SSL verification disabled for kubectl download"; \
        curl -k -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH:-amd64}/kubectl" && \
        curl -k -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH:-amd64}/kubectl.sha256"; \
    else \
        curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH:-amd64}/kubectl" && \
        curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH:-amd64}/kubectl.sha256"; \
    fi && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum -c && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl kubectl.sha256 && \
    kubectl version --client && \
    echo "kubectl installation complete"

# Copy appropriate Gemfile based on CINC major version
# Supports v6 (stable) and v7 (latest)
COPY Gemfile.v${CINC_MAJOR_VERSION} /tmp/Gemfile
RUN echo "Using CINC Auditor v${CINC_MAJOR_VERSION}" && cat /tmp/Gemfile

# Install CINC Auditor via gems AS ROOT with --system
WORKDIR /tmp
ENV BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_SSL_VERIFY_MODE=${SSL_NO_VERIFY:+0}
RUN if [ "$SSL_NO_VERIFY" = "true" ]; then \
        echo "WARNING: SSL verification disabled for gem installation (BUNDLE_SSL_VERIFY_MODE=0)"; \
    fi && \
    bundle install --system && \
    gem install bigdecimal:3.1.8

# Install plugins from git repositories AS ROOT
COPY plugin-repos.txt /tmp/plugin-repos.txt
WORKDIR /tmp
RUN if [ "$SSL_NO_VERIFY" = "true" ]; then \
        echo "WARNING: SSL verification disabled for git clone"; \
        git config --global http.sslVerify false; \
    fi && \
    \
    echo "Installing plugins from git repositories..." && \
    plugin_count=0 && \
    \
    # Process single plugin from build args
    if [ -n "$PLUGIN_GIT_REPO" ]; then \
        echo "Installing plugin: ${PLUGIN_GIT_REPO} (branch: ${PLUGIN_GIT_BRANCH})"; \
        git clone --branch "${PLUGIN_GIT_BRANCH}" --depth 1 "${PLUGIN_GIT_REPO}" "/tmp/plugin-${plugin_count}"; \
        cd "/tmp/plugin-${plugin_count}"; \
        GEMSPEC=$(ls ./*.gemspec | head -1); \
        if [ -n "$GEMSPEC" ]; then \
            gem build "$GEMSPEC"; \
            cinc-auditor plugin install ./*.gem; \
            echo "  ✓ Plugin installed successfully"; \
            plugin_count=$((plugin_count + 1)); \
        else \
            echo "  ✗ WARNING: No gemspec found in repository"; \
        fi; \
        cd /tmp; \
        rm -rf "/tmp/plugin-${plugin_count}"; \
    fi && \
    \
    # Process multiple plugins from plugin-repos.txt
    if [ -f "/tmp/plugin-repos.txt" ]; then \
        while IFS= read -r line; do \
            case "$line" in \
                \#*) continue ;; \
                "") continue ;; \
            esac; \
            \
            repo=$(echo "$line" | awk '{print $1}'); \
            branch=$(echo "$line" | awk '{print $2}'); \
            branch=${branch:-main}; \
            \
            if [ "$repo" = "$PLUGIN_GIT_REPO" ]; then \
                echo "Skipping $repo (already installed via build arg)"; \
                continue; \
            fi; \
            \
            echo "Installing plugin: ${repo} (branch: ${branch})"; \
            git clone --branch "${branch}" --depth 1 "${repo}" "/tmp/plugin-${plugin_count}"; \
            cd "/tmp/plugin-${plugin_count}"; \
            GEMSPEC=$(ls ./*.gemspec | head -1); \
            if [ -n "$GEMSPEC" ]; then \
                gem build "$GEMSPEC"; \
                cinc-auditor plugin install ./*.gem; \
                echo "  ✓ Plugin installed successfully"; \
                plugin_count=$((plugin_count + 1)); \
            else \
                echo "  ✗ WARNING: No gemspec found in repository"; \
            fi; \
            cd /tmp; \
            rm -rf "/tmp/plugin-${plugin_count}"; \
        done < /tmp/plugin-repos.txt; \
    fi && \
    \
    echo "Total plugins installed from git: ${plugin_count}" && \
    rm -f /tmp/plugin-repos.txt

# Install additional plugins from .gem files AS ROOT
COPY plugins/ /tmp/plugins/
WORKDIR /tmp/plugins
RUN if [ -d "/tmp/plugins" ] && [ -n "$(ls -A /tmp/plugins/*.gem 2>/dev/null)" ]; then \
        echo "Installing additional InSpec/Train plugins from .gem files..."; \
        for gemfile in ./*.gem; do \
            [ -f "$gemfile" ] || continue; \
            echo "Installing plugin: $gemfile"; \
            cinc-auditor plugin install "$gemfile"; \
            echo "  -> Installed successfully"; \
        done; \
        rm -rf /tmp/plugins; \
    else \
        echo "No additional plugin .gem files found in plugins/ directory"; \
    fi

# Cleanup build dependencies to reduce image size
RUN apk del build-base ruby-dev libxml2-dev libffi-dev && \
    rm -rf /tmp/* /var/cache/apk/*

# Create .kube directory for kubeconfig
RUN mkdir -p /root/.kube

# Set working directory and initialize git to silence InSpec warnings
WORKDIR /workspace
RUN git init . && git config user.name "CINC Auditor" && git config user.email "cinc@localhost"

# Environment variables
# Redirect git stderr to suppress "not a git repository" warnings from InSpec plugin loader
ENV TRAIN_K8S_SESSION_MODE=true \
    KUBECONFIG=/root/.kube/config \
    GIT_CEILING_DIRECTORIES=/

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD cinc-auditor version || exit 1

# Default command
CMD ["cinc-auditor", "version"]
