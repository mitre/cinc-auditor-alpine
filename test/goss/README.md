# Goss/dgoss Testing (Alternative/Bonus Demo)

This directory contains Goss configuration for testing CINC Auditor Alpine containers as an alternative to InSpec profile testing.

## What is Goss/dgoss?

- **Goss**: Fast YAML-based server validation tool
- **dgoss**: Docker wrapper for Goss
- **Speed**: Very fast (runs in milliseconds)
- **Simplicity**: Pure YAML configuration

## Installation

```bash
# Install goss
curl -fsSL https://goss.rocks/install | sh

# Install dgoss
curl -L https://raw.githubusercontent.com/aelsabbahy/goss/master/extras/dgoss/dgoss -o /usr/local/bin/dgoss
chmod +x /usr/local/bin/dgoss
```

## Usage

### Test v6 Image
```bash
cd test/goss
GOSS_VARS=goss-vars-v6.yaml dgoss run cinc-auditor-alpine:6
```

### Test v7 Image
```bash
cd test/goss
GOSS_VARS=goss-vars-v7.yaml dgoss run cinc-auditor-alpine:7
```

### Render Template (Debug)
```bash
# See what the final test file looks like after variable substitution
goss --vars goss-vars-v6.yaml render
```

## Files

- `goss.yaml` - Main test file with Go template syntax
- `goss-vars-v6.yaml` - Variables for v6 testing
- `goss-vars-v7.yaml` - Variables for v7 testing

## Updating for New Releases

When releasing a new version, update the appropriate vars file:

```yaml
# goss-vars-v6.yaml
cinc_version: "6.9"  # Update version
kubectl_version: "v1.32"  # Update if kubectl changed
ruby_version: "3.4"  # Update if Ruby changed
expected_plugins:
  - "train-k8s-container"
  # Add new plugins here if needed
```

The `goss.yaml` test file never needs to change!

## Comparison with InSpec

| Feature | InSpec Profile | Goss/dgoss |
|---------|----------------|------------|
| Speed | Medium (~5s) | Very Fast (<1s) |
| Language | Ruby DSL | YAML |
| Templates | Inputs (Ruby) | Go templates |
| Primary Use | Compliance testing | Server validation |
| Best For | Complex logic | Simple checks |

**Recommendation**: Use InSpec profile as primary tests (we're a CINC container!). Use Goss for quick smoke tests or demos.
