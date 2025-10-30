# InSpec/Train Plugin Gems

Place additional InSpec or Train plugin `.gem` files in this directory to install them during the Docker build.

## Default Plugins

The image includes these plugins by default:
- **train-k8s-container v2.0** - Kubernetes container testing (from MITRE GitHub)

## Adding Custom Plugins

### Option 1: From .gem Files (Local)

If you have pre-built `.gem` files for InSpec or Train plugins:

```bash
# Copy .gem file to plugins directory
cp /path/to/your-plugin.gem plugins/

# Build the image
./scripts/build.sh
```

The build process will automatically install all `.gem` files found in this directory.

### Option 2: Build from Source

If you need to build a plugin gem from source first:

```bash
# Clone and build the gem
git clone https://github.com/your-org/your-plugin.git /tmp/your-plugin
cd /tmp/your-plugin
gem build your-plugin.gemspec

# Copy to plugins directory
cp your-plugin-*.gem /path/to/cinc-auditor-alpine/plugins/

# Build the image
cd /path/to/cinc-auditor-alpine
./scripts/build.sh
```

## Supported Plugin Types

- **InSpec plugins** - Extend InSpec functionality (reporters, CLI commands, etc.)
- **Train plugins** - Add new transport backends (AWS, Azure, K8s, etc.)

## Examples

### Installing train-kubernetes Plugin

```bash
# Download or build the gem
gem install train-kubernetes --install-dir /tmp
cp /tmp/gems/train-kubernetes-*.gem plugins/
```

### Installing Multiple Plugins

```bash
# Copy multiple plugins
cp ~/downloads/inspec-reporter-*.gem plugins/
cp ~/downloads/train-aws-*.gem plugins/
cp ~/downloads/train-habitat-*.gem plugins/

# All will be installed during build
./scripts/build.sh
```

## Verification

After building, verify plugins are installed:

```bash
docker run --rm cinc-auditor-alpine:latest cinc-auditor plugin list
```

## Notes

- Plugin `.gem` files are NOT committed to git (see `.gitignore`)
- Only `.gem` files are processed - source code in this directory is ignored
- Plugins are installed after CINC Auditor and train-k8s-container
- Failed plugin installations will show warnings but won't stop the build
