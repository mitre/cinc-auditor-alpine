# Research Findings - Community Best Practices

Research conducted on existing CINC Auditor and InSpec Docker implementations.

## Key Findings

### 1. CINC Installation Methods

#### Official CINC Project (GitLab)
- **Source**: https://gitlab.com/cinc-project/docker-images/-/tree/master/docker-auditor
- **Method**: Gem-based installation from rubygems.cinc.sh
- **Base**: Alpine Linux
- **Gemfile approach**:
  ```ruby
  gem "cinc-auditor-core-bin", source: "https://rubygems.cinc.sh"
  gem "cinc-auditor-bin", source: "https://rubygems.cinc.sh"
  gem "inspec", source: "https://rubygems.cinc.sh"
  ```
- **Key packages**: `build-base`, `libxml2-dev`, `libffi-dev`, `git`, `openssh-client`, `ruby`, `ruby-dev`, `ruby-etc`, `ruby-webrick`, `ruby-bundler`
- **Cleanup**: Remove `build-base` and `ruby-dev` after installation to reduce image size

#### Polymathrobotics/OCI
- **Source**: https://github.com/polymathrobotics/oci/tree/main/cinc/cinc-auditor
- **Method**: .deb package installation
- **Base**: Ubuntu noble (24.04) - required for GLIBC_2.38 dependency
- **Multi-arch**: Separate download URLs for amd64 and arm64
- **Benefits**:
  - Pre-compiled binaries (faster builds)
  - Consistent versions across architectures
  - SHA256 verification for security
- **Drawbacks**:
  - Larger base image (Ubuntu vs Alpine)
  - Limited to architectures with .deb packages

### 2. SSL Verification Handling

From Stack Overflow and GitHub code searches:

#### Git
```bash
# Global config
git config --global http.sslVerify false

# Environment variable alternative
GIT_SSL_NO_VERIFY=true git clone https://...
```

#### cURL
```bash
curl -k https://...           # Short form
curl --insecure https://...   # Long form
```

#### Ruby Bundler/Gems
```bash
# Bundler config
bundle config set --global ssl_verify_mode 0

# Force refresh gem sources (clears SSL cache)
gem sources --remove https://rubygems.org/
gem sources --add https://rubygems.org/
```

### 3. Docker Best Practices

#### Multi-stage Builds
- Separate build and runtime stages
- Keep build dependencies out of final image
- Example from polymathrobotics:
  ```dockerfile
  FROM base AS download
  # Download and verify

  FROM base
  COPY --from=download /tmp/package.deb
  # Install without build deps
  ```

#### Layer Optimization
- Combine related RUN commands
- Use heredoc syntax for complex operations:
  ```dockerfile
  RUN <<EOF
    apt-get update
    apt-get install -y package1 package2
    cleanup commands
  EOF
  ```

#### Cleanup Best Practices
- Remove package lists: `rm -rf /var/lib/apt/lists/*`
- Remove temp files: `rm -rf /tmp/* /var/tmp/*`
- Remove build deps: `apk del build-base ruby-dev`
- Ubuntu auto-runs `apt-get clean` (no manual invocation needed)

### 4. Architecture Support

#### polymathrobotics approach:
```dockerfile
dpkgArch="$(dpkg --print-architecture)"
case "${dpkgArch##*-}" in
  amd64) URL="$URL_AMD64" ;;
  arm64) URL="$URL_ARM64" ;;
  *) echo "unsupported architecture"; exit 1 ;;
esac
```

#### CINC GitLab approach:
```dockerfile
FROM alpine:3.19 AS base-linux-amd64
FROM alpine:3.19 AS base-linux-arm64
FROM base-linux-${TARGETARCH}
```

### 5. Testing Approach

polymathrobotics uses:
- InSpec profiles in `test/controls/` directory
- Automated testing with `cinc-auditor` to test the image itself
- GitHub Actions for CI/CD
- `bin/test-matrix.sh` script for running tests

## Recommendations for Our Implementation

### What We're Doing Right:
✅ Alpine base (minimal attack surface)
✅ Gem-based installation (follows official CINC project)
✅ Multi-stage architecture support
✅ Certificate handling for corporate environments
✅ SSL verification options
✅ Plugin flexibility (git repos + .gem files)

### What We Could Improve:

1. **Consider .deb Packages as Alternative**
   - Faster builds (pre-compiled)
   - Better for production (consistent versions)
   - Could offer both Alpine (gem) and Ubuntu (deb) variants

2. **Add Heredoc Syntax**
   - Cleaner, more readable RUN commands
   - Better for complex certificate processing

3. **Add InSpec-based Tests**
   - Test the image with CINC Auditor itself
   - Create `test/controls/` directory with InSpec tests
   - Automated testing in CI/CD

4. **Better Layer Optimization**
   - Combine certificate processing into single RUN
   - Combine plugin installation into single RUN
   - Reduce total layer count

5. **Add docker-bake.hcl**
   - Modern BuildKit approach
   - Better multi-arch builds
   - More maintainable than long build scripts

## Potential Issues to Watch For

### Alpine-Specific Challenges:
- ⚠️ Ruby native extensions may fail (nokogiri, ffi, etc.)
- ⚠️ musl vs glibc compatibility issues
- ⚠️ Some gems expect glibc (Alpine uses musl)

### Solutions if Alpine Causes Issues:
1. Use Ubuntu base like polymathrobotics (proven to work)
2. Install glibc compatibility layer in Alpine
3. Pre-compile problematic gems

### CINC Auditor Gem Installation:
- ⚠️ `bigdecimal` gem must be manually installed (missing dependency)
- ⚠️ Requires build tools that should be removed after installation

## Next Steps

1. **Test current Alpine gem-based approach**
   - Try basic build first
   - Check for native extension failures
   - Verify plugin installation works

2. **If Alpine has issues, consider Ubuntu variant**
   - Follow polymathrobotics pattern
   - Use .deb packages
   - Faster, more reliable builds

3. **Add proper testing**
   - Create InSpec test profile
   - Test CINC Auditor functionality
   - Test train-k8s-container plugin
   - Test kubectl integration

4. **Optimize Dockerfile**
   - Use heredoc syntax
   - Combine layers
   - Better cleanup

## References

- CINC Project GitLab: https://gitlab.com/cinc-project/docker-images
- polymathrobotics/oci: https://github.com/polymathrobotics/oci
- train-k8s-container v2.0: https://github.com/mitre/train-k8s-container/tree/v2.0
- Docker Best Practices: https://docs.docker.com/build/building/best-practices/
