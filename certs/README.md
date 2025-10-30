# Custom Certificates

Place your corporate or custom CA certificates in this directory. Both `.crt` and `.pem` formats are supported.

## Supported Formats

- **PEM format**: `.pem` and `.crt` extensions
- **DER format**: `.der` and `.cer` extensions (binary format, common in DoD/Windows environments)
- **Certificate bundles**: Files containing multiple certificates are automatically split into individual certificates

The Dockerfile automatically handles:
- `.pem` and `.crt` files (PEM format, copies as-is)
- `.der` and `.cer` files (DER format, converts to PEM using OpenSSL)
- `.cer` files that are actually PEM format (detects and handles correctly)
- Multi-certificate bundles (splits into individual certificates)

## Usage

1. Copy your certificate(s) to this directory:
   ```bash
   # PEM format (.pem or .crt)
   cp $SSL_CERT_FILE certs/corporate-ca.pem

   # DER format (.der or .cer) - common in DoD environments
   cp /path/to/dod-root-ca.cer certs/

   # From extracted ZIP files
   unzip dod-certs.zip -d certs/
   ```

2. Build the image with certificates:
   ```bash
   ./scripts/build.sh --with-certs
   # or simply
   ./scripts/build.sh
   ```

## Examples

### Single Certificate
```bash
# Copy from environment variable (keep original extension)
cp $SSL_CERT_FILE certs/corporate-ca.pem
```

### Certificate Bundle
If you have a bundle with multiple certificates (common in enterprise environments), just copy it here. The build process will automatically:
- Convert DER format (`.der`, `.cer`) to PEM format
- Split bundles into individual certificate files
- Convert all certificates to `.crt` extension (Alpine's update-ca-certificates requirement)
- Install all certificates into the system trust store

### DoD Certificate Bundles
DoD commonly distributes certificates in ZIP files containing `.cer` files in DER format:
```bash
# Extract DoD certificates
unzip dod-certificates.zip -d certs/

# Build will automatically convert all .cer files to PEM format
./scripts/build.sh
```

### Verify Installation
After building, verify certificates are installed:
```bash
docker run --rm cinc-auditor-alpine:latest \
  ls -la /usr/local/share/ca-certificates/corp/
```

## Security Note

⚠️ **Certificates in this directory are NOT committed to git** (see `.gitignore`)

This is intentional to prevent accidentally committing corporate or sensitive CA certificates to version control.
