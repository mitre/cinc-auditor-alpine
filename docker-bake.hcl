# Docker Bake configuration for CINC Auditor Alpine
# Build multiple versions and architectures with one command

# Variables for customization
variable "TAG_PREFIX" {
  default = "cinc-auditor-alpine"
}

variable "DOCKER_HUB_REPO" {
  default = "mitre/cinc-auditor-alpine"
}

variable "KUBECTL_VERSION" {
  default = "1.32.11"
}

variable "SSL_NO_VERIFY" {
  default = "false"
}

variable "PLUGIN_GIT_REPO" {
  default = "https://github.com/mitre/train-k8s-container.git"
}

variable "PLUGIN_GIT_BRANCH" {
  default = "v2.2.0"
}

# Detect local platform (macOS needs linux override)
variable "LOCAL_PLATFORM" {
  default = regex_replace("${BAKE_LOCAL_PLATFORM}", "^(darwin)", "linux")
}

variable "GIT_SHA" {
  default = ""
}

variable "BUILD_DATE" {
  default = ""
}

# Common configuration shared by all targets
target "_common" {
  dockerfile = "Dockerfile"
  args = {
    KUBECTL_VERSION = "${KUBECTL_VERSION}"
    SSL_NO_VERIFY = "${SSL_NO_VERIFY}"
    PLUGIN_GIT_REPO = "${PLUGIN_GIT_REPO}"
    PLUGIN_GIT_BRANCH = "${PLUGIN_GIT_BRANCH}"
  }
  labels = {
    "org.opencontainers.image.source" = "https://github.com/mitre/cinc-auditor-alpine"
    "org.opencontainers.image.licenses" = "Apache-2.0"
    "org.opencontainers.image.description" = "CINC Auditor with train-k8s-container and kubectl on Alpine Linux"
    "org.opencontainers.image.authors" = "Aaron Lippold <lippold@gmail.com>"
    "org.opencontainers.image.created" = "${BUILD_DATE != "" ? BUILD_DATE : timestamp()}"
    "org.opencontainers.image.revision" = "${GIT_SHA}"
    "org.opencontainers.image.url" = "https://hub.docker.com/r/mitre/cinc-auditor-alpine"
    "org.opencontainers.image.documentation" = "https://github.com/mitre/cinc-auditor-alpine#readme"
    "com.mitre.kubectl.version" = "${KUBECTL_VERSION}"
    "com.mitre.train-k8s-container.version" = "${PLUGIN_GIT_BRANCH}"
  }
}

# Group: Build all versions
group "default" {
  targets = ["v6", "v7"]
}

# Group: Build all with multi-arch
group "all" {
  targets = ["v6-multiarch", "v7-multiarch"]
}

# CINC Auditor v6 (Stable) - Local platform only
target "v6" {
  inherits = ["_common"]
  args = {
    CINC_MAJOR_VERSION = "6"
  }
  tags = [
    "${TAG_PREFIX}:6",
    "${TAG_PREFIX}:6.8",
    "${TAG_PREFIX}:6.8.24",
    "${TAG_PREFIX}:latest"
  ]
  platforms = ["${LOCAL_PLATFORM}"]
}

# CINC Auditor v6 (Stable) - Multi-architecture
target "v6-multiarch" {
  inherits = ["_common"]
  args = {
    CINC_MAJOR_VERSION = "6"
  }
  tags = [
    "${DOCKER_HUB_REPO}:6",
    "${DOCKER_HUB_REPO}:6.8",
    "${DOCKER_HUB_REPO}:6.8.24",
    "${DOCKER_HUB_REPO}:latest"
  ]
  platforms = ["linux/amd64", "linux/arm64"]
}

# CINC Auditor v7 (Stable) - Local platform only
target "v7" {
  inherits = ["_common"]
  args = {
    CINC_MAJOR_VERSION = "7"
  }
  tags = [
    "${TAG_PREFIX}:7",
    "${TAG_PREFIX}:7.0",
    "${TAG_PREFIX}:7.0.95"
  ]
  platforms = ["${LOCAL_PLATFORM}"]
}

# CINC Auditor v7 (Stable) - Multi-architecture
target "v7-multiarch" {
  inherits = ["_common"]
  args = {
    CINC_MAJOR_VERSION = "7"
  }
  tags = [
    "${DOCKER_HUB_REPO}:7",
    "${DOCKER_HUB_REPO}:7.0",
    "${DOCKER_HUB_REPO}:7.0.95"
  ]
  platforms = ["linux/amd64", "linux/arm64"]
}

# Development target with SSL bypass
target "dev-vpn" {
  inherits = ["_common"]
  args = {
    CINC_MAJOR_VERSION = "6"
    SSL_NO_VERIFY = "true"
  }
  tags = ["${TAG_PREFIX}:dev-vpn"]
  platforms = ["${LOCAL_PLATFORM}"]
}
