# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## CINC 7.0.95 + kubectl 1.32.11 - 2026-01-04

### Changed
- Updated CINC Auditor v7 from 7.0.52.beta to 7.0.95 (stable)
- Removed `.beta` suffix from all v7 tags
- Adopted industry-standard tagging (upstream versions as tags, no container semver)
- Updated README with Docker Tags section explaining tagging strategy

### Dependencies
- CINC Auditor v6: 6.8.24
- CINC Auditor v7: 7.0.95  
- kubectl: 1.31.4
- train-k8s-container: 2.2.0
- Alpine: 3.19

## CINC 6.8.24 + kubectl 1.31.4 - 2026-01-03

### Added
- Initial release following industry tagging standards
- Multi-architecture support (linux/amd64, linux/arm64)
- Docker Build Cloud integration for native ARM64 builds
- Comprehensive testing (Goss, InSpec, Container Structure Tests)
- Corporate certificate support

### Changed  
- Upgraded train-k8s-container from v2.0 to v2.2.0
- Fixed multi-platform builds with proper TARGETARCH declaration
- Simplified release workflow

### Dependencies
- CINC Auditor v6: 6.8.24
- CINC Auditor v7: 7.0.52.beta
- kubectl: 1.31.4
- train-k8s-container: 2.2.0
- Alpine: 3.19

Authored by: Aaron Lippold <lippold@gmail.com>
