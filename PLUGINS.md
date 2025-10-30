# Plugin Installation Guide

This image supports three methods for installing InSpec and Train plugins.

## Method 1: Git Repositories (Recommended)

Edit `plugin-repos.txt` to add multiple plugins from git repositories:

```bash
# plugin-repos.txt format:
# git_repo_url branch_name

https://github.com/mitre/train-k8s-container.git v2.0
https://github.com/your-org/train-custom.git main
https://github.com/inspec/train-habitat.git main
```

### Features:
- ✅ Install multiple plugins automatically
- ✅ Specify branch/tag for each plugin
- ✅ Automatically builds gems from source
- ✅ Works with internal/private repos (with SSL config)

### Example:

```bash
# Copy example file
cp plugin-repos.txt.example plugin-repos.txt

# Edit to add your plugins
vim plugin-repos.txt

# Build image
./scripts/build.sh
```

## Method 2: Single Plugin via Build Arg

Override the default plugin via command-line:

```bash
# Install different plugin
./scripts/build.sh \
  --plugin-repo https://github.com/your-org/your-plugin.git \
  --plugin-branch v2.1.0
```

### Features:
- ✅ Quick one-off builds
- ✅ Good for testing different versions
- ✅ Backward compatible

## Method 3: Pre-built .gem Files

Place `.gem` files in the `plugins/` directory:

```bash
# Download or build gem
cp ~/Downloads/train-custom-0.1.0.gem plugins/

# Build image
./scripts/build.sh
```

### Features:
- ✅ Works with gems not in git
- ✅ No network access needed during build
- ✅ Good for air-gapped environments

## Combined Example

You can use all three methods together:

```bash
# 1. Add plugins to plugin-repos.txt
echo "https://github.com/org1/plugin1.git main" >> plugin-repos.txt
echo "https://github.com/org2/plugin2.git v1.0" >> plugin-repos.txt

# 2. Add a gem file
cp custom-plugin.gem plugins/

# 3. Override one via build arg
./scripts/build.sh \
  --plugin-repo https://github.com/org3/plugin3.git \
  --plugin-branch dev

# Result: All plugins from plugin-repos.txt + custom-plugin.gem + plugin3 will be installed
```

## Corporate Environments

For environments with SSL inspection or internal certificate authorities:

```bash
# Add your corporate certificates
cp $SSL_CERT_FILE certs/corporate-ca.pem

# Build with SSL verification disabled for git clones
./scripts/build.sh --ssl-no-verify
```

## Verification

After building, verify plugins are installed:

```bash
docker run --rm cinc-auditor-alpine:latest cinc-auditor plugin list
```

## Troubleshooting

### Plugin fails to install
- Check that the repository has a `.gemspec` file
- Verify the branch name is correct
- Try with `--no-cache` to force a fresh build

### SSL errors during git clone
- Add corporate certificates to `certs/`
- Use `--ssl-no-verify` flag (less secure, but works with corporate proxies)

### Plugin not found after build
- Check build logs for errors
- Verify gem was built successfully
- Run `cinc-auditor plugin list` to see installed plugins
