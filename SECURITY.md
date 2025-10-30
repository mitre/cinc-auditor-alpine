# Security Policy

## Reporting Security Issues

The MITRE SAF team takes security seriously. If you discover a security vulnerability in this project, please report it responsibly.

### Contact Information

- **Email**: [saf-security@mitre.org](mailto:saf-security@mitre.org)
- **GitHub**: Use the [Security tab](https://github.com/mitre/cinc-auditor-alpine/security) to report vulnerabilities privately

### What to Include

When reporting security issues, please provide:

1. **Description** of the vulnerability
2. **Steps to reproduce** the issue
3. **Potential impact** assessment
4. **Suggested fix** (if you have one)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 7 days
- **Fix Timeline**: Varies by severity

## Security Best Practices

### For Users

- **Keep Updated**: Use the latest version of CINC Auditor Alpine
- **Secure Credentials**: Never commit kubeconfig files or certificates to version control
- **Use Read-Only Mounts**: Mount kubeconfig and certificates as read-only (`:ro`)
- **Network Security**: Use secure networks when scanning infrastructure

### For Contributors

- **Dependency Scanning**: Run Hadolint and container structure tests before submitting PRs
- **Credential Handling**: Never log or expose credentials in code
- **Image Scanning**: Scan Docker images for vulnerabilities regularly
- **Test Security**: Include security tests for new features

## Supported Versions

| Version | Status | Supported |
|---------|--------|-----------|
| v6.x    | Stable | ✅ Yes    |
| v7.x    | Beta   | ⚠️ Beta   |

## Security Testing

This project includes comprehensive security testing:

```bash
# Run Hadolint (Dockerfile linting)
hadolint Dockerfile

# Run container structure tests
container-structure-test test --image cinc-auditor-alpine:6 --config container-structure-test.yaml

# Run functional tests
./tests/test-functional.sh cinc-auditor-alpine:6
```

## Known Security Considerations

### Container Security
- Images run as root (standard for CLI tool containers)
- Alpine Linux base for minimal attack surface
- No unnecessary packages installed
- Multi-stage build to minimize final image size

### Certificate Handling
- Custom certificates supported for corporate environments
- Certificates added to Alpine trust store during build
- SSL_NO_VERIFY flag available for development (not recommended for production)

### Kubernetes Access
- Requires kubeconfig file mounted at runtime
- Uses kubectl exec for container access
- Respects Kubernetes RBAC policies
- No credentials stored in image

### Dependencies
- CINC Auditor from rubygems.cinc.sh
- kubectl from official Kubernetes releases
- train-k8s-container plugin from MITRE GitHub

## Vulnerability Disclosure

We follow coordinated vulnerability disclosure practices. Security issues will be addressed according to severity:

- **Critical**: Immediate patch release
- **High**: Patch within 7 days
- **Medium**: Patch within 30 days
- **Low**: Addressed in next release
